using Godot;
using System;
using IntercableConnectris.Database;
using System.Collections.Generic;

namespace IntercableConnectris.UI;

public partial class MainMenu : Control
{
    private VBoxContainer _highscoreList;
    private HighscoreDB _db;

    public override void _Ready()
    {
        _db = new HighscoreDB();
        
        GetNode<Button>("VBoxContainer/PlayButton").Pressed += OnPlayPressed;
        GetNode<Button>("VBoxContainer/QuitButton").Pressed += OnQuitPressed;
        
        _highscoreList = GetNode<VBoxContainer>("HighscorePanel/VBoxContainer/List");
        
        LoadHighscores();
    }

    private void LoadHighscores()
    {
        // Clear existing
        foreach (Node child in _highscoreList.GetChildren())
        {
            child.QueueFree();
        }

        List<HighscoreEntry> topScores = _db.GetTopHighscores(10);
        foreach (var entry in topScores)
        {
            var label = new Label();
            label.Text = $"{entry.Initials.PadRight(3)} - Score: {entry.Score} - Lvl: {entry.Level}";
            label.HorizontalAlignment = HorizontalAlignment.Center;
            _highscoreList.AddChild(label);
        }
    }

    private void OnPlayPressed()
    {
        GetTree().ChangeSceneToFile("res://scenes/PlayfieldScene.tscn");
    }

    private void OnQuitPressed()
    {
        GetTree().Quit();
    }
}
