using Godot;
using System;

using IntercableConnectris.UI;
using IntercableConnectris.Database;

public partial class Playfield : Node2D
{
    private TetrisGrid _grid;
    private PowerUpManager _powerUpManager;
    private TetrisBlock _currentBlock;

    private float _fallTimer = 0f;
    private float _fallInterval = 1.0f;
    
    private int _score = 0;
    private int _level = 1;
    private bool _gameOver = false;

    private AudioStreamPlayer _sfxLock;
    private AudioStreamPlayer _sfxLaser;
    private AudioStreamPlayer _sfxCut;
    private Label _scoreLabel;

    private static readonly bool[][,] TetrominoShapes = new bool[][,]
    {
        new bool[,] { { false, false, false, false }, { true,  true,  true,  true }, { false, false, false, false }, { false, false, false, false } }, // I
        new bool[,] { { true,  false, false }, { true,  true,  true }, { false, false, false } }, // J
        new bool[,] { { false, false, true }, { true,  true,  true }, { false, false, false } }, // L
        new bool[,] { { true, true }, { true, true } }, // O
        new bool[,] { { false, true,  true }, { true,  true,  false }, { false, false, false } }, // S
        new bool[,] { { false, true,  false }, { true,  true,  true }, { false, false, false } }, // T
        new bool[,] { { true,  true,  false }, { false, true,  true }, { false, false, false } }  // Z
    };

    private static readonly Color[] TetrominoColors = new Color[]
    {
        Colors.Cyan, Colors.Blue, Colors.Orange, Colors.Yellow, Colors.Green, Colors.Purple, Colors.Red
    };

    public override void _Ready()
    {
        // Setup Grid
        _grid = new TetrisGrid();
        _grid.Name = "TetrisGrid";
        AddChild(_grid);

        // Setup PowerUpManager
        _powerUpManager = new PowerUpManager();
        _powerUpManager.Name = "PowerUpManager";
        _powerUpManager.Grid = _grid;
        AddChild(_powerUpManager);

        // Setup Audio
        _sfxLock = new AudioStreamPlayer { Stream = GD.Load<AudioStream>("res://assets/audio/pressen.wav") };
        _sfxLaser = new AudioStreamPlayer { Stream = GD.Load<AudioStream>("res://assets/audio/laser_zischen.wav") };
        _sfxCut = new AudioStreamPlayer { Stream = GD.Load<AudioStream>("res://assets/audio/schneiden.wav") };
        AddChild(_sfxLock);
        AddChild(_sfxLaser);
        AddChild(_sfxCut);

        // Setup Score UI
        var uiLayer = new CanvasLayer();
        _scoreLabel = new Label 
        { 
            Text = "Score: 0\nLevel: 1",
            Position = new Vector2(20, 20)
        };
        _scoreLabel.AddThemeFontSizeOverride("font_size", 32);
        uiLayer.AddChild(_scoreLabel);
        AddChild(uiLayer);

        SpawnNewBlock();
    }

    public override void _Process(double delta)
    {
        if (_currentBlock == null || _gameOver) return;

        _fallTimer += (float)delta;
        if (_fallTimer >= _fallInterval)
        {
            _fallTimer = 0f;
            MoveBlockDown();
        }

        HandleInput();

        if (_currentBlock != null)
        {
            // Sync pixel position with grid (48px)
            _currentBlock.Position = new Vector2(_currentBlock.GridPosition.X * 48, _currentBlock.GridPosition.Y * 48);
        }
    }

    private void HandleInput()
    {
        if (Input.IsActionJustPressed("ui_left") || Input.IsActionJustPressed("ui_touch_left") || Input.IsActionJustPressed("ui_joypad_left"))
        {
            MoveBlockHorizontal(-1);
        }
        else if (Input.IsActionJustPressed("ui_right") || Input.IsActionJustPressed("ui_touch_right") || Input.IsActionJustPressed("ui_joypad_right"))
        {
            MoveBlockHorizontal(1);
        }

        // Hard Drop
        if (Input.IsActionJustPressed("ui_select") || Input.IsActionJustPressed("ui_accept"))
        {
            HardDrop();
            return;
        }

        // Soft Drop
        if (Input.IsActionPressed("ui_down") || Input.IsActionPressed("ui_touch_down") || Input.IsActionPressed("ui_joypad_down"))
        {
            _fallInterval = 0.05f;
        }
        else
        {
            _fallInterval = Math.Max(0.1f, 1.0f - ((_level - 1) * 0.05f));
        }

        if (Input.IsActionJustPressed("ui_up") || Input.IsActionJustPressed("ui_touch_up") || Input.IsActionJustPressed("ui_joypad_up"))
        {
            RotateBlock();
        }
    }

    private void HardDrop()
    {
        while (_grid.IsValidPosition(_currentBlock, new Vector2I(0, 1)))
        {
            _currentBlock.GridPosition += new Vector2I(0, 1);
            _score += 2;
        }
        MoveBlockDown(); // Trigger lock
    }

    private void MoveBlockHorizontal(int dir)
    {
        if (_grid.IsValidPosition(_currentBlock, new Vector2I(dir, 0)))
        {
            _currentBlock.GridPosition += new Vector2I(dir, 0);
        }
    }

    private void MoveBlockDown()
    {
        if (_grid.IsValidPosition(_currentBlock, new Vector2I(0, 1)))
        {
            _currentBlock.GridPosition += new Vector2I(0, 1);
        }
        else
        {
            _sfxLock?.Play();
            _grid.LockBlock(_currentBlock);
            _score += 100; // Increase score when block is locked
            UpdateScoreUI();
            
            _currentBlock.QueueFree();
            _currentBlock = null;
            SpawnNewBlock();
        }
    }

    private void UpdateScoreUI()
    {
        if (_scoreLabel != null)
        {
            _scoreLabel.Text = $"Score: {_score}\nLevel: {_level}";
        }
    }

    private void RotateBlock()
    {
        _currentBlock.RotateRight();
        if (!_grid.IsValidPosition(_currentBlock, Vector2I.Zero))
        {
            // Wall Kick (Basic)
            if (_grid.IsValidPosition(_currentBlock, new Vector2I(-1, 0))) {
                _currentBlock.GridPosition += new Vector2I(-1, 0);
            } else if (_grid.IsValidPosition(_currentBlock, new Vector2I(1, 0))) {
                _currentBlock.GridPosition += new Vector2I(1, 0);
            } else if (_grid.IsValidPosition(_currentBlock, new Vector2I(0, -1))) {
                _currentBlock.GridPosition += new Vector2I(0, -1);
            } else {
                // Revert if all fail
                _currentBlock.RotateLeft();
            }
        }
    }

    private void SpawnNewBlock()
    {
        _currentBlock = new TetrisBlock();
        
        int shapeIndex = (int)(GD.Randi() % 7);
        _currentBlock.ShapeMatrix = (bool[,])TetrominoShapes[shapeIndex].Clone();
        _currentBlock.BlockColor = TetrominoColors[shapeIndex];

        int cols = _currentBlock.ShapeMatrix.GetLength(1);
        _currentBlock.GridPosition = new Vector2I((TetrisGrid.Columns - cols) / 2, 0);
        _currentBlock.SetCableState(CableState.Isolated);

        AddChild(_currentBlock);
        
        // Check game over
        if (!_grid.IsValidPosition(_currentBlock, Vector2I.Zero))
        {
            GD.Print("Game Over!");
            _gameOver = true;
            _currentBlock.QueueFree();
            _currentBlock = null;
            
            TriggerGameOverUI();
        }
    }

    private void TriggerGameOverUI()
    {
        var keyboardScene = GD.Load<PackedScene>("res://scenes/Keyboard.tscn");
        var keyboardInstance = keyboardScene.Instantiate<Keyboard>();
        
        var canvasLayer = new CanvasLayer();
        canvasLayer.AddChild(keyboardInstance);
        AddChild(canvasLayer);

        keyboardInstance.InitialsEntered += OnInitialsEntered;
    }

    private void OnInitialsEntered(string initials)
    {
        // Save highscore
        var db = new HighscoreDB();
        db.AddHighscore(initials, _score, _level);

        // Return to main menu
        GetTree().ChangeSceneToFile("res://scenes/MainMenu.tscn");
    }
}
