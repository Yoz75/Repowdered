/// Module that handles various input. It is fully separated from window and can be used without it.
module sednalib.input;
import std.container.binaryheap;
import raylib;

/// State of an input action
public enum InputActionState : ubyte
{
    /// Uninitialized enum value. Input actions never return this value
    none = 0,
    /// Input action is unactive
    unactive,
    /// Input action began perfomring
    began,
    /// Input action is performing
    performing,
    /// Input action ended performing
    ended
}

public enum MouseButton
{
    left = 0,
    right = 1,
    middle = 2,
    sideButton1 = 3,
    sideButton2 = 4
}

/// Keyboard keys
public enum KeyboardKey
{
    /// Key: none, used for no key pressed
    none = 0,

    /// Key: '
    apostrophe = 39,

    /// Key: ,
    comma = 44,

    /// Key: -
    minus = 45,

    /// Key: .
    period = 46,

    /// Key: /
    slash = 47,

    /// Key: 0
    zero = 48,

    /// Key: 1
    one = 49,

    /// Key: 2
    two = 50,

    /// Key: 3
    three = 51,

    /// Key: 4
    four = 52,

    /// Key: 5
    five = 53,

    /// Key: 6
    six = 54,

    /// Key: 7
    seven = 55,

    /// Key: 8
    eight = 56,

    /// Key: 9
    nine = 57,

    /// Key: ;
    semicolon = 59,

    /// Key: =
    equal = 61,

    /// Key: A | a
    a = 65,

    /// Key: B | b
    b = 66,

    /// Key: C | c
    c = 67,

    /// Key: D | d
    d = 68,

    /// Key: E | e
    e = 69,

    /// Key: F | f
    f = 70,

    /// Key: G | g
    g = 71,

    /// Key: H | h
    h = 72,

    /// Key: I | i
    i = 73,

    /// Key: J | j
    j = 74,

    /// Key: K | k
    k = 75,

    /// Key: L | l
    l = 76,

    /// Key: M | m
    m = 77,

    /// Key: N | n
    n = 78,

    /// Key: O | o
    o = 79,

    /// Key: P | p
    p = 80,

    /// Key: Q | q
    q = 81,

    /// Key: R | r
    r = 82,

    /// Key: S | s
    s = 83,

    /// Key: T | t
    t = 84,

    /// Key: U | u
    u = 85,

    /// Key: V | v
    v = 86,

    /// Key: W | w
    w = 87,

    /// Key: X | x
    x = 88,

    /// Key: Y | y
    y = 89,

    /// Key: Z | z
    z = 90,

    /// Key: [
    leftBracket = 91,

    /// Key: '\'
    backslash = 92,

    /// Key: ]
    rightBracket = 93,

    /// Key: `
    grave = 96,

    // Function keys

    /// Key: Space
    space = 32,

    /// Key: Esc
    escape = 256,

    /// Key: Enter
    enter = 257,

    /// Key: Tab
    tab = 258,

    /// Key: Backspace
    backspace = 259,

    /// Key: Ins
    insert = 260,

    /// Key: Del
    delete_ = 261, // delete — keyword conflict safety

    /// Key: arrow right
    right = 262,

    /// Key: arrow left
    left = 263,

    /// Key: arrow down
    down = 264,

    /// Key: arrow up
    up = 265,

    /// Key: Page up
    pageUp = 266,

    /// Key: Page down
    pageDown = 267,

    /// Key: Home
    home = 268,

    /// Key: End
    end = 269,

    /// Key: Caps lock
    capsLock = 280,

    /// Key: Scroll lock
    scrollLock = 281,

    /// Key: Num lock
    numLock = 282,

    /// Key: Print screen
    printScreen = 283,

    /// Key: Pause
    pause = 284,

    /// Key: F1
    f1 = 290,

    /// Key: F2
    f2 = 291,

    /// Key: F3
    f3 = 292,

    /// Key: F4
    f4 = 293,

    /// Key: F5
    f5 = 294,

    /// Key: F6
    f6 = 295,

    /// Key: F7
    f7 = 296,

    /// Key: F8
    f8 = 297,

    /// Key: F9
    f9 = 298,

    /// Key: F10
    f10 = 299,

    /// Key: F11
    f11 = 300,

    /// Key: F12
    f12 = 301,


    /// Key: F13
    f13 = 302,

    /// Key: F14
    f14 = 303,

    /// Key: F15
    f15 = 304,

    /// Key: F16
    f16 = 305,

    /// Key: F17
    f17 = 306,

    /// Key: F18
    f18 = 307,

    /// Key: F19
    f19 = 308,

    /// Key: F20
    f20 = 309,

    /// Key: F21
    f21 = 310,

    /// Key: F22
    f22 = 311,

    /// Key: F23
    f23 = 312,

    /// Key: F24
    f24 = 313,

    /// Key: Shift left
    leftShift = 340,

    /// Key: Control left
    leftControl = 341,

    /// Key: Alt left
    leftAlt = 342,

    /// Key: Super left
    leftSuper = 343,

    /// Key: Shift right
    rightShift = 344,

    /// Key: Control right
    rightControl = 345,

    /// Key: Alt right
    rightAlt = 346,

    /// Key: Super right
    rightSuper = 347,

    /// Key: KB menu
    kbMenu = 348,

    // Keypad keys

    /// Key: Keypad 0
    kp0 = 320,

    /// Key: Keypad 1
    kp1 = 321,

    /// Key: Keypad 2
    kp2 = 322,

    /// Key: Keypad 3
    kp3 = 323,

    /// Key: Keypad 4
    kp4 = 324,

    /// Key: Keypad 5
    kp5 = 325,

    /// Key: Keypad 6
    kp6 = 326,

    /// Key: Keypad 7
    kp7 = 327,

    /// Key: Keypad 8
    kp8 = 328,

    /// Key: Keypad 9
    kp9 = 329,

    /// Key: Keypad .
    kpDecimal = 330,

    /// Key: Keypad /
    kpDivide = 331,

    /// Key: Keypad *
    kpMultiply = 332,

    /// Key: Keypad -
    kpSubtract = 333,

    /// Key: Keypad +
    kpAdd = 334,

    /// Key: Keypad Enter
    kpEnter = 335,

    /// Key: Keypad =
    kpEqual = 336,

    // Android key buttons

    /// Key: Android back button
    back = 4,

    /// Key: Android menu button
    menu = 5,

    /// Key: Android volume up button
    volumeUp = 24,

    /// Key: Android volume down button
    volumeDown = 25
}

/// Various information about mouse
public final abstract class Mouse
{
static:
    /// Get the position of the mouse on screen
    /// Returns: mouse position in format [x, y]
    public float[2] getPosition()
    {
        immutable position = raylib.GetMousePosition();
        return [position.x, position.y];
    }
}

/// Some user input that can begin be performed and end
public interface IInputAction
{
    /// Get the state of input action
    /// Returns: an `InputActionState` instance. Returned value is never `InputActionState.none`
    public InputActionState getState();
}

/// Some user input that can be represented as a float axis
public interface IAxisInputAction : IInputAction
{
    /// Get axis of the input. May be any float value.
    public float getAxis();
}

/// An input action received from keyboard
public final class KeyboardInputAction : IInputAction
{
    private KeyboardKey key;
    private bool wasPressedAtPreviousCheck;

    public this(KeyboardKey key)
    {
        this.key = key;
    }

    public InputActionState getState()
    {
        immutable isPressed = IsKeyDown(key);

        auto result = InputActionState.unactive;
        if(isPressed && !wasPressedAtPreviousCheck) result = InputActionState.began;
        else if(!isPressed && wasPressedAtPreviousCheck) result = InputActionState.ended;
        else if(isPressed) result = InputActionState.performing;

        wasPressedAtPreviousCheck = isPressed;
        return result;
    }
}

/// An input action received from keyboard and representable as a float axis. 
/// May be -1 (first key is pressed), 0 (both keys up or both down) and 1 (second key is pressed)
public final class KeyboardAxisInputAction : IInputAction, IAxisInputAction
{
    private KeyboardKey firstKey, secondKey;
    private bool wasFirstPressedAtPreviousCheck, wasSecondPressedAtPreviousCheck;

    public this(KeyboardKey first, KeyboardKey second)
    {
        firstKey = first;
        secondKey = second;
    }

    public InputActionState getState()
    {
        immutable isFirstPressed = IsKeyDown(firstKey);
        immutable isSecondPressed = IsKeyDown(secondKey);

        auto result = InputActionState.unactive;

        if((isFirstPressed && !wasFirstPressedAtPreviousCheck) || (isSecondPressed && !wasSecondPressedAtPreviousCheck))
         result = InputActionState.began;
        else if((!isFirstPressed && wasFirstPressedAtPreviousCheck) || (!isSecondPressed && wasSecondPressedAtPreviousCheck))
         result = InputActionState.ended;
        else if(isFirstPressed || isSecondPressed)
         result = InputActionState.performing;

        wasFirstPressedAtPreviousCheck = isFirstPressed;
        wasSecondPressedAtPreviousCheck = isSecondPressed;
        return result;
    }

    /// Get axis of the input. May be any float value.
    public float getAxis()
    {
        return -1 * IsKeyDown(firstKey) + 1 * IsKeyDown(secondKey);
    }
}

/// An input action received from mouse and representable as a float axis. Works bad with multithreading.
public final class MouseWheelAxisInputAction : IInputAction, IAxisInputAction
{
    public InputActionState getState()
    {
        if(GetMouseWheelMove != 0) return InputActionState.performing;
        return InputActionState.unactive;
    }
    /// Get axis of the input. May be any float value.
    public float getAxis()
    {
        return GetMouseWheelMove();
    }
}

public final class MouseButtonInputAction : IInputAction
{
    private MouseButton button;
    private bool wasPressedAtPreviousCheck;

    public this(MouseButton button)
    {
        this.button = button;
    }

    public InputActionState getState()
    {
        immutable isPressed = IsMouseButtonDown(button);

        auto result = InputActionState.unactive;

        if(isPressed && !wasPressedAtPreviousCheck) result = InputActionState.began;
        else if(!isPressed && wasPressedAtPreviousCheck) result = InputActionState.ended;
        else if(isPressed) result = InputActionState.performing;

        wasPressedAtPreviousCheck = isPressed;
        return result;
    }
}

/// An input action, combined from two other. 
/// When states of first and second actions are different, `CombinedInputAction` is unactive.
/// When states of first and second actions are same, `CombinedInputAction` has the same state.
public final class CombinedInputAction : IInputAction
{
    private IInputAction first, second;
    private bool isFirstReversed, isSecondReversed;

    public this(IInputAction first, IInputAction second, bool isFirstReversed = false, bool isSecondReversed = false)
    {
        this.first = first;
        this.second = second;
        
        this.isFirstReversed = isFirstReversed;
        this.isSecondReversed = isSecondReversed;
    }

    public InputActionState getState()
    {
        immutable firstState = first.getState();
        immutable secondState = second.getState();

        immutable bool resultFirst 
         = isFirstReversed ? firstState != InputActionState.unactive : firstState != InputActionState.unactive;
        immutable bool resultSecond 
         = isSecondReversed ? secondState != InputActionState.unactive : secondState != InputActionState.unactive;

        if(resultFirst == resultSecond)
        {
            // Or secondState, whatever
            return firstState;
        }
        
        return InputActionState.unactive;
    }
}

/// Resolves witch one of N input actions is active right now using priorities
public final class InputActionResolver
{
    private struct PriorityAction
    {
        IInputAction action;
        int priority;

        public int opCmp(ref const PriorityAction other) const
        {
            return priority - other.priority;
        }
    }

    private PriorityAction[] priorityHeap;

    public void addInputAction(IInputAction action, int priority)
    {
        priorityHeap ~= PriorityAction(action, priority);
        heapify(priorityHeap);
    }

    /// Get the state of `action` given its priority
    /// Returns: the state of the action
    public InputActionState getState(IInputAction action)
    {
        foreach(priorityAction; priorityHeap)
        {
            if(priorityAction.action is action)
            {
                return action.getState();
            }
            else if(priorityAction.action.getState() != InputActionState.unactive)
            {
                return InputActionState.unactive;
            }
        }

        throw new Exception("Input action is null or not contained in the resolver!");
    }
}

/// Is action active? Assumes action's state can never be `InputActionState.none`
/// Params:
/// action = the action to be checked
/// Returns: true if action state is not `InputActionState.unactive``
public bool isActive(IInputAction action)
{
    return action.getState() != InputActionState.unactive;
} 