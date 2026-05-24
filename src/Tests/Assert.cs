using System;

namespace IntercableConnectris.Tests;

public static class Assert
{
    public static void IsTrue(bool condition, string message = "")
    {
        if (!condition) throw new Exception($"Assert.IsTrue failed. {message}");
    }
    
    public static void IsFalse(bool condition, string message = "")
    {
        if (condition) throw new Exception($"Assert.IsFalse failed. {message}");
    }
    
    public static void AreEqual<T>(T expected, T actual, string message = "")
    {
        if (!System.Collections.Generic.EqualityComparer<T>.Default.Equals(expected, actual))
            throw new Exception($"Assert.AreEqual failed. Expected: {expected}, Actual: {actual}. {message}");
    }

    public static void IsNotNull(object obj, string message = "")
    {
        if (obj == null) throw new Exception($"Assert.IsNotNull failed. {message}");
    }
}
