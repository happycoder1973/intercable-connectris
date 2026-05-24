using Godot;
using System;
using System.Reflection;
using System.Linq;

namespace IntercableConnectris.Tests;

public partial class TestRunner : Node
{
    public override void _Ready()
    {
        GD.Print("\n=================================");
        GD.Print("      RUNNING C# TESTS             ");
        GD.Print("=================================");
        
        int failed = 0;
        int passed = 0;

        var assembly = Assembly.GetExecutingAssembly();
        var testClasses = assembly.GetTypes()
            .Where(t => t.Name.EndsWith("Tests") && t.IsClass && t.Namespace != "Godot");

        foreach (var testClass in testClasses)
        {
            GD.Print($"\nRunning tests in {testClass.Name}...");
            object instance = null;
            try
            {
                instance = Activator.CreateInstance(testClass);
            }
            catch (Exception ex)
            {
                GD.PrintErr($"[ERROR] Could not instantiate {testClass.Name}: {ex.Message}");
                failed++;
                continue;
            }

            var methods = testClass.GetMethods()
                .Where(m => m.Name.StartsWith("Test"));

            foreach (var method in methods)
            {
                try
                {
                    method.Invoke(instance, null);
                    GD.Print($"  [PASS] {method.Name}");
                    passed++;
                }
                catch (Exception e)
                {
                    GD.PrintErr($"  [FAIL] {method.Name}: {e.InnerException?.Message ?? e.Message}");
                    failed++;
                }
            }
        }

        GD.Print("\n=================================");
        GD.Print($"Tests completed: {passed} passed, {failed} failed.");
        GD.Print("=================================\n");

        // Exit immediately using deferred call
        GetTree().CallDeferred("Quit", failed > 0 ? 1 : 0);
    }
}
