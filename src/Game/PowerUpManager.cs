using Godot;
using System;

public enum PowerUpType
{
    AMXLaser,       // Löscht Spalte
    STILO60Beben,   // Schüttelt Grid
    SlickCutter,    // Schneidet Reihe
    VDESchutzschild // Blockiert Fehler
}

public partial class PowerUpManager : Node
{
    [Export]
    public TetrisGrid Grid { get; set; }

    public bool IsShieldActive { get; private set; }

    public override void _Ready()
    {
        IsShieldActive = false;
    }

    public void ActivatePowerUp(PowerUpType type, int targetIndex = 0)
    {
        switch (type)
        {
            case PowerUpType.AMXLaser:
                // Löscht eine bestimmte Spalte (targetIndex = Spalte)
                GD.Print("AMX-Laser aktiviert! Lösche Spalte: ", targetIndex);
                Grid?.ClearColumn(targetIndex);
                break;

            case PowerUpType.STILO60Beben:
                // Schüttelt das Grid (alle Blöcke fallen nach unten)
                GD.Print("STILO60-Beben aktiviert! Grid wird geschüttelt.");
                Grid?.ShakeGrid();
                break;

            case PowerUpType.SlickCutter:
                // Schneidet eine bestimmte Reihe (targetIndex = Reihe)
                GD.Print("Slick-Cutter aktiviert! Lösche Reihe: ", targetIndex);
                Grid?.ClearRow(targetIndex);
                break;

            case PowerUpType.VDESchutzschild:
                // Aktiviert den Schutzschild für den nächsten Fehler
                GD.Print("VDE-Schutzschild aktiviert! Fehler werden blockiert.");
                IsShieldActive = true;
                break;
        }
    }

    public bool TryConsumeShield()
    {
        if (IsShieldActive)
        {
            GD.Print("VDE-Schutzschild hat einen Fehler abgeblockt!");
            IsShieldActive = false;
            return true;
        }
        return false;
    }
}
