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

    public override void _Ready()
    {
        // Initialization if needed
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
        // Visual update could be triggered here
        QueueRedraw();
    }
}
