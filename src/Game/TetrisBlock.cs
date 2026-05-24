using Godot;
using System;
using System.Collections.Generic;

public enum CableState
{
    Isolated, // Isoliert
    Bare,     // Blank
    Crimped   // Gecrimpt
}

public partial class TetrisBlock : Node2D
{
    public Vector2I GridPosition { get; set; }
    public CableState CurrentCableState { get; set; }
    
    // Matrix for the block shape (true means solid)
    public bool[,] ShapeMatrix { get; set; }
    public Color BlockColor { get; set; }

    private Texture2D _texture;

    public override void _Ready()
    {
        UpdateTexture();
    }

    private void UpdateTexture()
    {
        string path = "res://assets/textures/isoliert.png";
        if (CurrentCableState == CableState.Bare) path = "res://assets/textures/blank.png";
        else if (CurrentCableState == CableState.Crimped) path = "res://assets/textures/gecrimpt.png";
        
        _texture = GD.Load<Texture2D>(path);
    }

    public void RotateRight()
    {
        int rows = ShapeMatrix.GetLength(0);
        int cols = ShapeMatrix.GetLength(1);
        bool[,] newMatrix = new bool[cols, rows];

        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                newMatrix[c, rows - 1 - r] = ShapeMatrix[r, c];
            }
        }
        ShapeMatrix = newMatrix;
    }

    public void RotateLeft()
    {
        int rows = ShapeMatrix.GetLength(0);
        int cols = ShapeMatrix.GetLength(1);
        bool[,] newMatrix = new bool[cols, rows];

        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                newMatrix[cols - 1 - c, r] = ShapeMatrix[r, c];
            }
        }
        ShapeMatrix = newMatrix;
    }
    
    public void SetCableState(CableState newState)
    {
        CurrentCableState = newState;
        UpdateTexture();
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (_texture == null || ShapeMatrix == null) return;

        int rows = ShapeMatrix.GetLength(0);
        int cols = ShapeMatrix.GetLength(1);
        int blockSize = 64;

        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                if (ShapeMatrix[r, c])
                {
                    DrawTexture(_texture, new Vector2(c * blockSize, r * blockSize), BlockColor);
                }
            }
        }
    }
}
