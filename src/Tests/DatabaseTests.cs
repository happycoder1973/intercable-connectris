using System;
using System.IO;
using Godot;
using IntercableConnectris.Database;

namespace IntercableConnectris.Tests;

public class DatabaseTests
{
    private string testDbPath = "user://test_highscore.db";

    public void TestDatabaseInitializationAndAddScore()
    {
        string globalPath = ProjectSettings.GlobalizePath(testDbPath);
        
        // Clean up previous test database if it exists
        if (File.Exists(globalPath))
        {
            File.Delete(globalPath);
        }

        var db = new HighscoreDB(testDbPath);
        Assert.IsTrue(File.Exists(globalPath), "Database file should be created.");

        // Test Adding and Retrieving
        db.AddHighscore("AAA", 100, 1);
        db.AddHighscore("BBB", 200, 2);

        var topScores = db.GetTopHighscores(10);
        Assert.AreEqual(2, topScores.Count, "Should retrieve exactly 2 scores.");
        
        // Top score should be BBB with 200
        Assert.AreEqual("BBB", topScores[0].Initials);
        Assert.AreEqual(200, topScores[0].Score);
        Assert.AreEqual(2, topScores[0].Level);

        // Second should be AAA with 100
        Assert.AreEqual("AAA", topScores[1].Initials);
        Assert.AreEqual(100, topScores[1].Score);

        // Cleanup
        if (File.Exists(globalPath))
        {
            File.Delete(globalPath);
        }
    }
}
