using Godot;
using System;
using System.Collections.Generic;

public partial class TetrisGrid : Node2D
{
    public const int Columns = 10;
    public const int Rows = 20;

    // Grid stores the cable state or null if empty
    // Using a nullable struct or class. We can use an object to store block data.
    public class CellData
    {
        public CableState State { get; set; }
        public Color Color { get; set; }
    }

    private CellData[,] _grid = new CellData[Columns, Rows];
    
    private Texture2D _texIsolated;
    private Texture2D _texBare;
    private Texture2D _texCrimped;

    public override void _Ready()
    {
        _texIsolated = GD.Load<Texture2D>("res://assets/textures/isoliert.png");
        _texBare = GD.Load<Texture2D>("res://assets/textures/blank.png");
        _texCrimped = GD.Load<Texture2D>("res://assets/textures/gecrimpt.png");
        ClearGrid();
    }

    public void ClearGrid()
    {
        for (int x = 0; x < Columns; x++)
        {
            for (int y = 0; y < Rows; y++)
            {
                _grid[x, y] = null;
            }
        }
    }

    public bool IsValidPosition(TetrisBlock block, Vector2I offset)
    {
        Vector2I newPos = block.GridPosition + offset;
        int rows = block.ShapeMatrix.GetLength(0);
        int cols = block.ShapeMatrix.GetLength(1);

        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                if (block.ShapeMatrix[r, c])
                {
                    int gridX = newPos.X + c;
                    int gridY = newPos.Y + r;

                    if (gridX < 0 || gridX >= Columns || gridY >= Rows)
                    {
                        return false; // Out of bounds
                    }

                    if (gridY >= 0 && _grid[gridX, gridY] != null)
                    {
                        return false; // Collision with existing block
                    }
                }
            }
        }

        return true;
    }

    public void LockBlock(TetrisBlock block)
    {
        int rows = block.ShapeMatrix.GetLength(0);
        int cols = block.ShapeMatrix.GetLength(1);

        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                if (block.ShapeMatrix[r, c])
                {
                    int gridX = block.GridPosition.X + c;
                    int gridY = block.GridPosition.Y + r;

                    if (gridY >= 0 && gridY < Rows && gridX >= 0 && gridX < Columns)
                    {
                        _grid[gridX, gridY] = new CellData 
                        { 
                            State = block.CurrentCableState, 
                            Color = block.BlockColor 
                        };
                    }
                }
            }
        }
        
        CheckFullRows();
    }

    public void CheckFullRows()
    {
        List<int> fullRows = new List<int>();

        for (int y = Rows - 1; y >= 0; y--)
        {
            bool isFull = true;
            for (int x = 0; x < Columns; x++)
            {
                if (_grid[x, y] == null)
                {
                    isFull = false;
                    break;
                }
            }

            if (isFull)
            {
                fullRows.Add(y);
            }
        }

        if (fullRows.Count > 0)
        {
            ClearRows(fullRows);
        }
    }

    private void ClearRows(List<int> rowsToClear)
    {
        // Sort descending so we can shift down correctly
        rowsToClear.Sort();
        rowsToClear.Reverse();

        foreach (int row in rowsToClear)
        {
            // Move everything above down by 1
            for (int y = row; y > 0; y--)
            {
                for (int x = 0; x < Columns; x++)
                {
                    _grid[x, y] = _grid[x, y - 1];
                }
            }

            // Clear top row
            for (int x = 0; x < Columns; x++)
            {
                _grid[x, 0] = null;
            }
        }
        
        // Notify about cleared rows (e.g., scoring)
        // EmitSignal(SignalName.RowsCleared, rowsToClear.Count);
        QueueRedraw(); // Request visual update
    }

    // Tools for PowerUpManager
    public void ClearColumn(int columnIndex)
    {
        if (columnIndex >= 0 && columnIndex < Columns)
        {
            for (int y = 0; y < Rows; y++)
            {
                _grid[columnIndex, y] = null;
            }
            QueueRedraw();
        }
    }

    public void ClearRow(int rowIndex)
    {
        if (rowIndex >= 0 && rowIndex < Rows)
        {
            ClearRows(new List<int> { rowIndex });
        }
    }

    public void ShakeGrid()
    {
        // Simple gravity: drop all blocks to the lowest possible empty space
        for (int x = 0; x < Columns; x++)
        {
            int emptyY = Rows - 1;
            for (int y = Rows - 1; y >= 0; y--)
            {
                if (_grid[x, y] != null)
                {
                    CellData cell = _grid[x, y];
                    _grid[x, y] = null;
                    _grid[x, emptyY] = cell;
                    emptyY--;
                }
            }
        }
        QueueRedraw();
    }

    public override void _Draw()
    {
        int blockSize = 48;

        // Draw grid background and border
        DrawRect(new Rect2(0, 0, Columns * blockSize, Rows * blockSize), new Color(0, 0, 0, 0.5f));
        DrawRect(new Rect2(0, 0, Columns * blockSize, Rows * blockSize), Colors.White, false, 2.0f);

        for (int x = 0; x < Columns; x++)
        {
            for (int y = 0; y < Rows; y++)
            {
                if (_grid[x, y] != null)
                {
                    CellData cell = _grid[x, y];
                    Texture2D tex = _texIsolated;
                    if (cell.State == CableState.Bare) tex = _texBare;
                    else if (cell.State == CableState.Crimped) tex = _texCrimped;

                    if (tex != null)
                    {
                        DrawTextureRect(tex, new Rect2(x * blockSize, y * blockSize, blockSize, blockSize), false, cell.Color);
                    }
                }
            }
        }
    }
}
