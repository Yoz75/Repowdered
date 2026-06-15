/// This module provides root UI elements for all other UI elements and various themes
module repowdered.ui;

import repowdered.settings;
import sednalib;

/// Init and prepare game UI. Should be called from the Sedna thread.
public void initUI(Window window)
{
    initThemes();
    initGameUIRoots(window);
}

private void initThemes()
{
    auto settings = Settings.uiSettings;
    // Actually fluid uses raylib color and I can safely cast one to other. But if anything chnage sometime, this will break 0-0
    Themes.defaultUIElement = Theme(
        rule!Frame
        (
            Rule.backgroundColor = cast(Color) settings.frameBackground
        ),

        rule!Button
        (
            Rule.backgroundColor = cast(Color) settings.background,
            Rule.textColor = cast(Color) settings.textColor,
            Rule.border = settings.outlineSize,
            Rule.borderStyle = colorBorder(cast(Color) settings.outline),
            Rule.margin = settings.margin,

            when!"a.isHovered"(
                Rule.backgroundColor = cast(Color) settings.selectedBackground
            ),

            when!"a.isFocused"(
                Rule.backgroundColor = cast(Color) settings.selectedBackground
            )
        )
    );
}

/// Initialize the `GameUIRoots`.
private void initGameUIRoots(Window gameWindow)
{
    enum actionsFrameNumerator = 32;
    enum contentFrameNumerator = 512;
    enum typesFrameNumerator = 48;
    enum infoFrameNumerator = 12;
    auto root = gameWindow.uiRoot;

    GameUIRoots.upperActionsFrame = hframe(.layout!(actionsFrameNumerator, "fill"));
    GameUIRoots.contentFrame = hframe(.layout!(contentFrameNumerator, "fill"));
    GameUIRoots.typesFrame = hframe(.layout!(typesFrameNumerator, "fill"));
    GameUIRoots.bottomInfoPanel = hframe(.layout!(infoFrameNumerator, "fill"));

    GameUIRoots.upperActionsFrame.theme = Themes.defaultUIElement;
    GameUIRoots.contentFrame.theme = Themes.defaultUIElement;
    GameUIRoots.typesFrame.theme = Themes.defaultUIElement;
    GameUIRoots.bottomInfoPanel.theme = Themes.defaultUIElement;

    root.children ~= GameUIRoots.upperActionsFrame;
    root.children ~= GameUIRoots.contentFrame;
    root.children ~= GameUIRoots.typesFrame;
    root.children ~= GameUIRoots.bottomInfoPanel;
    root.updateSize();
}

public final class Themes
{
public:
static:

    /// Default UI element theme.
    Theme defaultUIElement;
}

/// Root UI elements for the Game scene
public final class GameUIRoots
{
public:
static:
    /// The Upper panel. There is placed UI, module button etc.
    Frame upperActionsFrame;

    /// The content panel. There is the game`s content categories list on the right side
    Frame contentFrame;

    /// The root for type buttons below content panel and above bottom info panel
    Frame typesFrame;

    /// The bottom panel for various information. The module/category/type description placed here.
    Frame bottomInfoPanel;
}