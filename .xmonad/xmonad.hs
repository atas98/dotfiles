{-
   __   _____  ___                      _
   \ \ / /|  \/  |                     | |
    \ V / | .  . | ___  _ __   __ _  __| |
    /   \ | |\/| |/ _ \| '_ \ / _` |/ _` |
   / /^\ \| |  | | (_) | | | | (_| | (_| |
   \/   \/\_|  |_/\___/|_| |_|\__,_|\__,_|
-}

-- !!! Imports !!! --

-- Base
import XMonad
import System.Directory
import System.IO (hPutStrLn)
import qualified XMonad.StackSet as W

-- Data
import Data.Char (isSpace, toUpper)
import Data.Maybe (fromJust)
import Data.Monoid
import Data.Maybe (isJust)
import Data.Tree
import qualified Data.Map as M
import System.Exit (exitSuccess)

-- Actions
import XMonad.Actions.CopyWindow (kill1)
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.MouseResize
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.WindowGo (runOrRaise)
import XMonad.Actions.WithAll (sinkAll, killAll)
import qualified XMonad.Actions.Search as S

-- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, doCenterFloat)
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory

-- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns

-- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import XMonad.Layout.WindowNavigation
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

-- Utilities
import XMonad.Util.Dmenu
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce

-- Colorscheme
import Colors.Dracula


-- !!! Variables !!! --

myFont :: String
myFont = "xft:SauceCodePro Nerd Font Mono:regular:size=9:antialias=true:hinting=true"

myModMask :: KeyMask
myModMask = mod4Mask

myTerminal :: String
myTerminal = "alacritty"

myBrowser :: String
myBrowser = "firefox "

myEmacs :: String
myEmacs = "emacsclient -c -a 'emacs' "

myEditor :: String
-- myEditor = "emacsclient -c -a 'emacs' "
myEditor = myTerminal ++ " -e vim "

-- Sets border width for windows
myBorderWidth :: Dimension
myBorderWidth = 2

-- Border color of normal windows
myNormColor :: String
myNormColor   = colorBack

-- Border color of focused windows
myFocusColor :: String
myFocusColor  = color15

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset


-- !!! Autostart !!! --

myStartupHook :: X ()
myStartupHook = do
    spawn "killall trayer"  -- kill current trayer on each restart
    spawnOnce "lxsession"
    spawnOnce "picom"
    spawnOnce "nm-applet"
    spawnOnce "volumeicon"
    -- spawnOnce "/usr/bin/emacs --daemon" -- emacs daemon for the emacsclient
    spawn (
      "sleep 2 && trayer \
        \ --edge top \
        \ --align right \
        \ --widthtype request \
        \ --padding 6 \
        \ --SetDockType true \
        \ --SetPartialStrut true \
        \ --expand true \
        \ --monitor 1 \
        \ --transparent true \
        \ --alpha 0 " ++ colorTrayer ++ " \
        \ --height 22")
    spawnOnce "nitrogen --restore &"
    setWMName "LG3D"


-- !!! Layouts !!! --

-- The spacingRaw module adds a configurable amount of space around windows.
myGaps :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
myGaps i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Setting colors for tabs layout and tabs sublayout.
myTabTheme = def {
  fontName = myFont,
  activeColor = color15,
  inactiveColor = color08,
  activeBorderColor = color15,
  inactiveBorderColor = colorBack,
  activeTextColor  = colorBack,
  inactiveTextColor = color16
}

tall = renamed [Replace "tall"]
  $ smartBorders
  $ windowNavigation
  $ addTabs shrinkText myTabTheme
  $ subLayout [] (smartBorders Simplest)
  $ limitWindows 12
  $ myGaps 8
  $ ResizableTall 1 (3/100) (1/2) []

grid = renamed [Replace "grid"]
  $ smartBorders
  $ windowNavigation
  $ addTabs shrinkText myTabTheme
  $ subLayout [] (smartBorders Simplest)
  $ limitWindows 12
  $ myGaps 8
  $ mkToggle (single MIRROR)
  $ Grid (16/10)

threeCol = renamed [Replace "threeCol"]
  $ smartBorders
  $ windowNavigation
  $ addTabs shrinkText myTabTheme
  $ subLayout [] (smartBorders Simplest)
  $ limitWindows 7
  $ ThreeColMid 1 (3/100) (1/2)

magnify = renamed [Replace "magnify"]
  $ smartBorders
  $ windowNavigation
  $ addTabs shrinkText myTabTheme
  $ subLayout [] (smartBorders Simplest)
  $ magnifier
  $ limitWindows 12
  $ myGaps 8
  $ ResizableTall 1 (3/100) (1/2) []

monocle  = renamed [Replace "monocle"]
  $ smartBorders
  $ windowNavigation
  $ addTabs shrinkText myTabTheme
  $ subLayout [] (smartBorders Simplest)
  $ limitWindows 20 Full

tabs     = renamed [Replace "tabs"]
  $ tabbed shrinkText myTabTheme

floats   = renamed [Replace "floats"]
  $ smartBorders
  $ limitWindows 20 simplestFloat

-- The layout hook
myLayoutHook = avoidStruts
  $ mouseResize
  $ windowArrange
  $ T.toggleLayouts floats
  $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
     where
       myDefaultLayout = withBorder myBorderWidth tall
        ||| magnify
        ||| noBorders monocle
        ||| floats
        ||| noBorders tabs
        ||| grid
        ||| threeCol

-- !!! Workspaces !!! --
myWorkspaces = [" 一 ", " 二 ", " 三 ", " 四 ", " 五 ", " 六 ", " 七 ", " 八 ", " 九 "] -- , " 十 "
myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..] -- (,) == \x y -> (x,y)

clickable ws = "<action=xdotool key super+"++show i++">"++ws++"</action>"
    where i = fromJust $ M.lookup ws myWorkspaceIndices


-- !!! Application Hooks !!! --
myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll [
  -- 'doFloat' forces a window to float.  Useful for dialog boxes and such.
  -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8
  className =? "confirm" --> doFloat,
  className =? "file_progress" --> doFloat,
  className =? "dialog" --> doFloat,
  className =? "download" --> doFloat,
  className =? "error" --> doFloat,
  className =? "notification" --> doFloat,
  className =? "toolbar" --> doFloat,
  className =? "Yad" --> doCenterFloat,
  className =? "Brave-browser" --> doShift ( myWorkspaces !! 1 ),
  className =? "mpv" --> doShift ( myWorkspaces !! 7 ),
  className =? "Gimp" --> doShift ( myWorkspaces !! 8 ),
  className =? "firefox" --> doShift ( myWorkspaces !! 1 ),
  (className =? "firefox" <&&> resource =? "Dialog") --> doFloat,  -- Float Firefox Dialog
  isFullscreen --> doFullFloat]

-- START_KEYS
myKeys :: [(String, X ())]
myKeys = [
-- KB_GROUP Xmonad
  ("M-C-r", spawn "xmonad --recompile"),       -- Recompiles xmonad
  ("M-S-r", spawn "xmonad --restart"),         -- Restarts xmonad
  ("M-<Esc>", io exitSuccess),                   -- Quits xmonad

-- KB_GROUP Get Help
  ("M-<F1>", spawn "~/.xmonad/xmonad_keys.sh"), -- Get list of keybindings

-- KB_GROUP Run Prompt
  ("M-d", spawn "dmenu_run"), -- Dmenu

-- KB_GROUP Useful programs to have a keybinding for launch
  ("M-<Return>", spawn (myTerminal)),
  ("M-b", spawn (myBrowser)),

-- KB_GROUP Kill windows
  ("M-q", kill1),     -- Kill the currently focused client
  ("M-S-q", killAll),   -- Kill all windows on current workspace

-- KB_GROUP Workspaces
  ("M-.", nextScreen),  -- Switch focus to next monitor
  ("M-,", prevScreen),  -- Switch focus to prev monitor
  ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP),       -- Shifts focused window to next ws
  ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP),  -- Shifts focused window to prev ws

-- KB_GROUP Floating windows
  ("M-s", sendMessage (T.Toggle "floats")), -- Toggles my 'floats' layout
  ("M-t", withFocused $ windows . W.sink),  -- Push floating window back to tile
  ("M-S-t", sinkAll),                       -- Push ALL floating windows to tile

-- KB_GROUP Increase/decrease spacing (gaps)
  ("C-M1-j", decWindowSpacing 4),         -- Decrease window spacing
  ("C-M1-k", incWindowSpacing 4),         -- Increase window spacing
  ("C-M1-h", decScreenSpacing 4),         -- Decrease screen spacing
  ("C-M1-l", incScreenSpacing 4),         -- Increase screen spacing

-- KB_GROUP Windows navigation
  ("M-m", windows W.focusMaster),  -- Move focus to the master window
  ("M-j", windows W.focusDown),    -- Move focus to the next window
  ("M-k", windows W.focusUp),      -- Move focus to the prev window
  ("M-S-m", windows W.swapMaster), -- Swap the focused window and the master window
  ("M-S-j", windows W.swapDown),   -- Swap focused window with next window
  ("M-S-k", windows W.swapUp),     -- Swap focused window with prev window
  ("M-<Backspace>", promote),      -- Moves focused window to master, others maintain order
  -- ("M-S-<Tab>", rotSlavesDown),    -- Rotate all windows except master and keep focus in place
  -- ("M-C-<Tab>", rotAllDown)       -- Rotate all the windows in the current stack

-- KB_GROUP Layouts
  ("M-<Tab>", sendMessage NextLayout),           -- Switch to next layout
  ("M-f", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts), -- Toggles noborder/full

-- KB_GROUP Increase/decrease windows in the master pane or the stack
  ("M-S-<Up>", sendMessage (IncMasterN 1)),      -- Increase # of clients master pane
  ("M-S-<Down>", sendMessage (IncMasterN (-1))), -- Decrease # of clients master pane
  ("M-C-<Up>", increaseLimit),                   -- Increase # of windows
  ("M-C-<Down>", decreaseLimit),                 -- Decrease # of windows

-- KB_GROUP Window resizing
  ("M-h", sendMessage Shrink),                   -- Shrink horiz window width
  ("M-l", sendMessage Expand),                   -- Expand horiz window width
  ("M-M1-j", sendMessage MirrorShrink),          -- Shrink vert window width
  ("M-M1-k", sendMessage MirrorExpand),          -- Expand vert window width

-- KB_GROUP Sublayouts
-- This is used to push windows to tabbed sublayouts, or pull them out of it.
  ("M-C-h", sendMessage $ pullGroup L),
  ("M-C-l", sendMessage $ pullGroup R),
  ("M-C-k", sendMessage $ pullGroup U),
  ("M-C-j", sendMessage $ pullGroup D),
  ("M-C-m", withFocused (sendMessage . MergeAll)),
  -- , ("M-C-u", withFocused (sendMessage . UnMerge))
  ("M-C-/", withFocused (sendMessage . UnMergeAll)),
  ("M-C-.", onGroup W.focusUp'),    -- Switch focus to next tab
  ("M-C-,", onGroup W.focusDown'),  -- Switch focus to prev tab

-- KB_GROUP Emacs (SUPER-e followed by a key)
  ("M-e e", spawn (myEmacs ++ ("--eval '(dashboard-refresh-buffer)'"))),   -- emacs dashboard
  ("M-e b", spawn (myEmacs ++ ("--eval '(ibuffer)'"))),   -- list buffers
  ("M-e d", spawn (myEmacs ++ ("--eval '(dired nil)'"))), -- dired
  ("M-e i", spawn (myEmacs ++ ("--eval '(erc)'"))),       -- erc irc client
  ("M-e n", spawn (myEmacs ++ ("--eval '(elfeed)'"))),    -- elfeed rss
  ("M-e s", spawn (myEmacs ++ ("--eval '(eshell)'"))),    -- eshell
  ("M-e t", spawn (myEmacs ++ ("--eval '(mastodon)'"))),  -- mastodon.el
  ("M-e v", spawn (myEmacs ++ ("--eval '(+vterm/here nil)'"))), -- vterm if on Doom Emacs
  ("M-e w", spawn (myEmacs ++ ("--eval '(doom/window-maximize-buffer(eww))'"))), -- eww browser if on Doom Emacs
  ("M-e a", spawn (myEmacs ++ ("--eval '(emms)' --eval '(emms-play-directory-tree \"~/Music/\")'"))), -- emms music player

-- KB_GROUP Multimedia Keys
  ("<XF86AudioPlay>", spawn "mocp --play"),
  ("<XF86AudioPrev>", spawn "mocp --previous"),
  ("<XF86AudioNext>", spawn "mocp --next"),
  ("<XF86AudioMute>", spawn "amixer set Master toggle"),
  ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%- unmute"),
  ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+ unmute"),
  ("<XF86HomePage>", spawn "firefox"),
  ("<XF86Search>", spawn "dm-websearch"),
  ("<XF86Mail>", runOrRaise "thunderbird" (resource =? "thunderbird")),
  ("<Print>", spawn "flameshot gui")]
  where nonNSP = WSIs (return (\ws -> W.tag ws /= "NSP"))
        nonEmptyNonNSP = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))

-- END_KEYS


main :: IO ()
main = do
  -- Launching xmobar
  xmproc0 <- spawnPipe ("xmobar -x 0 $HOME/.config/xmobar/xmobarrc")
  -- the xmonad, ya know...what the WM is named after!
  xmonad $ ewmh def {
    manageHook = myManageHook <+> manageDocks,
    handleEventHook = docksEventHook <+> fullscreenEventHook,
    modMask = myModMask,
    terminal = myTerminal,
    startupHook = myStartupHook,
    layoutHook = myLayoutHook,
    workspaces = myWorkspaces,
    borderWidth = myBorderWidth,
    normalBorderColor = myNormColor,
    focusedBorderColor = myFocusColor,
    logHook = dynamicLogWithPP $ xmobarPP {

    -- XMOBAR SETTINGS
    ppOutput = \x -> hPutStrLn xmproc0 x,   -- xmobar on monitor 1

    -- Current workspace
    ppCurrent = xmobarColor color06 "" . wrap
                ("<box type=Bottom width=2 mb=2 color=" ++ color06 ++ ">") "</box>",
    -- Visible but not current workspace
    ppVisible = xmobarColor color06 "" . clickable,
    -- Hidden workspace
    ppHidden = xmobarColor color05 "" . wrap
                ("<box type=Top width=2 mt=2 color=" ++ color05 ++ ">") "</box>" . clickable,
    -- Hidden workspaces (no windows)
    ppHiddenNoWindows = xmobarColor color05 ""  . clickable,
    -- Title of active window
    ppTitle = xmobarColor color16 "" . shorten 6,
    -- Separator character
    ppSep =  "<fc=" ++ color09 ++ "> <fn=1>|</fn> </fc>",
    -- Urgent workspace
    ppUrgent = xmobarColor color02 "" . wrap "!" "!",
    -- Adding # of windows on current workspace to the bar
    ppExtras  = [windowCount],
    -- order of things in xmobar
    ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]}
} `additionalKeysP` myKeys

