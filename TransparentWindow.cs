using Godot;
using System;
using System.Runtime.InteropServices;

[GlobalClass]
public partial class TransparentWindow : Node
{
    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    // For 32-bit compatibility
    [DllImport("user32.dll", SetLastError = true)]
    static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    const int GWL_EXSTYLE = -20;
    const int WS_EX_TRANSPARENT = 0x20;
    const int WS_EX_LAYERED = 0x80000;

    private IntPtr hwnd;
    private bool is64Bit;

    public override void _Ready()
    {
        hwnd = (IntPtr)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle, 0);
        is64Bit = IntPtr.Size == 8;

        GD.Print($"Window handle: {hwnd}");
        GD.Print($"Running in {(is64Bit ? "64" : "32")}-bit mode");
    }

    public void set_click_through(bool enabled)
    {
        try
        {
            if (is64Bit)
            {
                IntPtr exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
                IntPtr newStyle;

                if (enabled)
                {
                    // Add transparent and layered flags
                    newStyle = new IntPtr(exStyle.ToInt64() | WS_EX_TRANSPARENT | WS_EX_LAYERED);
                }
                else
                {
                    // Remove transparent flag, keep layered
                    newStyle = new IntPtr((exStyle.ToInt64() | WS_EX_LAYERED) & ~WS_EX_TRANSPARENT);
                }

                SetWindowLongPtr(hwnd, GWL_EXSTYLE, newStyle);
            }
            else
            {
                int exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
                int newStyle;

                if (enabled)
                {
                    newStyle = exStyle | WS_EX_TRANSPARENT | WS_EX_LAYERED;
                }
                else
                {
                    newStyle = (exStyle | WS_EX_LAYERED) & ~WS_EX_TRANSPARENT;
                }

                SetWindowLong(hwnd, GWL_EXSTYLE, newStyle);
            }

            GD.Print($"Click-through set to: {enabled}");
        }
        catch (Exception e)
        {
            GD.PrintErr($"Error setting click-through: {e.Message}");
        }
    }
}