using Godot;
using System;

namespace IntercableConnectris.UI;

public partial class Keyboard : Control
{
    [Signal]
    public delegate void InitialsEnteredEventHandler(string initials);

    private string _currentInitials = "";
    private Label _initialsLabel;

    public override void _Ready()
    {
        _initialsLabel = GetNode<Label>("Panel/VBoxContainer/InitialsLabel");
        
        var grid = GetNode<GridContainer>("Panel/VBoxContainer/GridContainer");
        foreach (Node child in grid.GetChildren())
        {
            if (child is Button btn)
            {
                // Capture the text locally to avoid closure issues
                string t = btn.Text;
                btn.Pressed += () => OnButtonPressed(t);
            }
        }
        UpdateLabel();
    }

    private void OnButtonPressed(string text)
    {
        if (text == "DEL")
        {
            if (_currentInitials.Length > 0)
                _currentInitials = _currentInitials.Substring(0, _currentInitials.Length - 1);
        }
        else if (text == "OK")
        {
            if (_currentInitials.Length > 0)
            {
                EmitSignal(SignalName.InitialsEntered, _currentInitials);
                QueueFree(); // Close keyboard
            }
        }
        else
        {
            if (_currentInitials.Length < 3)
            {
                _currentInitials += text;
            }
        }

        UpdateLabel();
    }
    
    private void UpdateLabel()
    {
        _initialsLabel.Text = _currentInitials.PadRight(3, '_');
    }
}
