<p><b>RealConsole</b> is a customisation system that lets you send more "personalised" logs to Roblox's dev console. Very simple to use!</p>

```luau
local RealConsole  = loadstring(game:HttpGet('https://raw.githubusercontent.com/malice-nz/RealConsole/main/main.lua'))':3';
```

## Examples
<img width="422" height="302" alt="RobloxPlayerBeta_W23THexHUf" src="https://github.com/user-attachments/assets/cabbd4b1-a0a6-42e6-8975-a2a2a658b60a" />

```luau
RealConsole:Output('Regular text');
RealConsole:Output("Regular text but with a different font", FontFace.new("rbxasset://fonts/families/RobotoMono.json"));

RealConsole:Info('I am an info!');
RealConsole:Warn('I am a warning!');
RealConsole:Error('I am an error!');
RealConsole:Error('I am an error but BIG!', Enum.Font.Code, 24);

RealConsole:Banner(TextureId, Text)
RealConsole:Image(TextureId)
```

## Functions

```luau
:Output(Text, Font?, Size?)
:Info(Text, Font?, Size?)
:Warn(Text, Font?, Size?)
:Error(Text, Font?, Size?)

:Image("rbxassetid://123", 96)
:Banner(Image, Text, Height, TextColour, Font)

:Custom(function(Row) ... end, Height)

:OpenConsole()
:Clear()
:Destroy()
```
