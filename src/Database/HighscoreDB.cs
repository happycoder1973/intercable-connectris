using System;
using System.Collections.Generic;
using Microsoft.Data.Sqlite;
using Godot;

namespace IntercableConnectris.Database;

public class HighscoreEntry
{
    public int Id { get; set; }
    public string Initials { get; set; } = string.Empty;
    public int Score { get; set; }
    public int Level { get; set; }
    public DateTime Date { get; set; }
}

public class HighscoreDB
{
    private readonly string _connectionString;

    /// <summary>
    /// Initializes the Highscore database connection.
    /// Uses Godot's user data path by default to ensure write access.
    /// </summary>
    /// <param name="dbPath">The path to the SQLite database file.</param>
    public HighscoreDB(string dbPath = "user://highscore.db")
    {
        // Convert Godot user:// path to actual filesystem path
        // Under Windows this is typically %APPDATA%\Godot\app_userdata\[Project_Name]
        string globalPath = ProjectSettings.GlobalizePath(dbPath);
        _connectionString = $"Data Source={globalPath};";
        
        InitializeDatabase();
    }

    /// <summary>
    /// Creates the Highscores table if it doesn't already exist.
    /// </summary>
    private void InitializeDatabase()
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS Highscores (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                Initials TEXT NOT NULL,
                Score INTEGER NOT NULL,
                Level INTEGER NOT NULL,
                Date TEXT NOT NULL
            );
        ";
        command.ExecuteNonQuery();
    }

    /// <summary>
    /// Inserts a new highscore entry.
    /// </summary>
    public void AddHighscore(string initials, int score, int level)
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"
            INSERT INTO Highscores (Initials, Score, Level, Date)
            VALUES ($initials, $score, $level, $date);
        ";
        
        command.Parameters.AddWithValue("$initials", initials);
        command.Parameters.AddWithValue("$score", score);
        command.Parameters.AddWithValue("$level", level);
        // ISO 8601 format string for SQLite date sorting
        command.Parameters.AddWithValue("$date", DateTime.UtcNow.ToString("O")); 

        command.ExecuteNonQuery();
    }

    /// <summary>
    /// Retrieves the top highscores ordered by score descending.
    /// </summary>
    /// <param name="limit">Max number of entries to return.</param>
    public List<HighscoreEntry> GetTopHighscores(int limit = 10)
    {
        var highscores = new List<HighscoreEntry>();

        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        // Order by Score descending. If scores are equal, older entries rank higher.
        command.CommandText = @"
            SELECT Id, Initials, Score, Level, Date 
            FROM Highscores 
            ORDER BY Score DESC, Date ASC
            LIMIT $limit;
        ";
        command.Parameters.AddWithValue("$limit", limit);

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            highscores.Add(new HighscoreEntry
            {
                Id = reader.GetInt32(0),
                Initials = reader.GetString(1),
                Score = reader.GetInt32(2),
                Level = reader.GetInt32(3),
                // Parse ISO 8601 string back to DateTime
                Date = DateTime.Parse(reader.GetString(4)).ToLocalTime()
            });
        }

        return highscores;
    }
}
