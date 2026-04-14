#!/usr/bin/env python3
"""
Mouse Control Utility for HOD Automation
Uses Quartz (built into macOS) for mouse operations
"""

import sys
import time
from Quartz import CGEventCreateMouseEvent, CGEventPost, kCGEventMouseMoved, kCGEventLeftMouseDown, kCGEventLeftMouseUp, kCGEventLeftMouseDragged, kCGMouseButtonLeft, kCGHIDEventTap

def mouse_move(x, y):
    """Move mouse to position"""
    event = CGEventCreateMouseEvent(None, kCGEventMouseMoved, (x, y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)

def mouse_click(x, y):
    """Click at position"""
    # Move to position
    mouse_move(x, y)
    time.sleep(0.05)
    
    # Mouse down
    event = CGEventCreateMouseEvent(None, kCGEventLeftMouseDown, (x, y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)
    time.sleep(0.05)
    
    # Mouse up
    event = CGEventCreateMouseEvent(None, kCGEventLeftMouseUp, (x, y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)

def mouse_drag(start_x, start_y, end_x, end_y):
    """Drag from start to end position"""
    # Move to start position
    mouse_move(start_x, start_y)
    time.sleep(0.05)
    
    # Mouse down at start
    event = CGEventCreateMouseEvent(None, kCGEventLeftMouseDown, (start_x, start_y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)
    time.sleep(0.1)
    
    # Drag to end position
    event = CGEventCreateMouseEvent(None, kCGEventLeftMouseDragged, (end_x, end_y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)
    time.sleep(0.1)
    
    # Mouse up at end
    event = CGEventCreateMouseEvent(None, kCGEventLeftMouseUp, (end_x, end_y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, event)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: mouse_control.py <command> <args>")
        print("Commands:")
        print("  move <x> <y>")
        print("  click <x> <y>")
        print("  drag <start_x> <start_y> <end_x> <end_y>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        if command == "move" and len(sys.argv) == 4:
            x, y = int(sys.argv[2]), int(sys.argv[3])
            mouse_move(x, y)
            print(f"Moved to ({x}, {y})")
        
        elif command == "click" and len(sys.argv) == 4:
            x, y = int(sys.argv[2]), int(sys.argv[3])
            mouse_click(x, y)
            print(f"Clicked at ({x}, {y})")
        
        elif command == "drag" and len(sys.argv) == 6:
            start_x, start_y = int(sys.argv[2]), int(sys.argv[3])
            end_x, end_y = int(sys.argv[4]), int(sys.argv[5])
            mouse_drag(start_x, start_y, end_x, end_y)
            print(f"Dragged from ({start_x}, {start_y}) to ({end_x}, {end_y})")
        
        else:
            print("Invalid command or arguments")
            sys.exit(1)
    
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

# Made with Bob
