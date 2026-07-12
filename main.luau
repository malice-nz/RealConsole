--!optimize 2

--# RealConsole
--? Spice up your developer console!

--* malice.nz
local cloneref	= cloneref or function(v) return v end;

--# Services #--
local LogService	= cloneref(game:GetService('LogService'));
local HttpService	= cloneref(game:GetService("HttpService"));
local CoreGui		= cloneref(game:GetService("CoreGui"));
local VirtualInput	= cloneref(game:GetService("VirtualInputManager"));

--# Types #--
local DefaultMessage	= {
	FontFace	= Enum.Font.Code,
	FontSize	= 15,
	ArrowOffset	= 20,
	LineHeight	= 16,
	IconHeight	= 14
};

local MessageTypes	= {
	Output	= {
		Color	= Color3.fromRGB(255, 255, 255),
		Icon	= '',
	},
	Info	= {
		Color	= Color3.fromRGB(0, 162, 255),
		Icon	= 'rbxasset://textures/DevConsole/Info.png',
	},
	Warn	= {
		Color	= Color3.fromRGB(255, 218, 68),
		Icon	= 'rbxasset://textures/DevConsole/Warning.png',
	},
	Error	= {
		Color	= Color3.fromRGB(215, 90, 74),
		Icon	= 'rbxasset://textures/DevConsole/Error.png',
	},
};

--# Class #--
local RealConsole = {}
RealConsole.__index = RealConsole

--# Functions #--
local function ApplyFont(Label, FontValue)
	if(typeof(FontValue) == "Font") then
		Label.FontFace = FontValue;
	elseif(typeof(FontValue) == "EnumItem") then
		Label.Font = FontValue;
	else
		Label.Font = DefaultMessage.FontFace;
	end;
end;

local function GetClientLogs()
	local Exists, Scroll = pcall(function()
		return(CoreGui:FindFirstChild('DevConsoleMaster')
			:FindFirstChild('DevConsoleWindow')
			:FindFirstChild('DevConsoleUI')
			:FindFirstChild('MainView')
			:FindFirstChild('ClientLog'))
	end);

	if(Exists and Scroll and Scroll:IsA("ScrollingFrame")) then
		return(Scroll);
	end;

	local DevConsole = CoreGui:FindFirstChild("DevConsoleMaster")
	if(DevConsole) then
		for _, Descendant in ipairs(DevConsole:GetDescendants()) do
			if(Descendant:IsA("ScrollingFrame") and Descendant:FindFirstChildOfClass("UIListLayout")) then
				for _, Child in ipairs(Descendant:GetChildren()) do
					if(Child:IsA("Frame") and Child:FindFirstChild("msg")) then
						return(Descendant)
					end
				end
			end
		end
	end
	return(nil)
end;

local function IsConsoleVisible()
	local DevConsole	= CoreGui:FindFirstChild("DevConsoleMaster");
	local Window		= DevConsole and DevConsole:FindFirstChild("DevConsoleWindow");
	return(Window ~= nil and Window.Visible == true);
end;

local function ApplySpec(Message, Spec)
	local Row	= Message.Parent;
	if(not Row) then return end;
	Message.TextTransparency	= 1;
	local NativeIcon = Row:FindFirstChild("image")
	if(NativeIcon) then NativeIcon.ImageTransparency = 1 end;
	if(Row:FindFirstChild("RC_content")) then return end;
	Spec.Apply(Row);
end;

--# Constructor #--
function RealConsole.New()
	local self		= setmetatable({}, RealConsole);
	self.Tracked	= {};
	self.Scroll		= nil;
	self.Alive		= true;

	self:Bind();

	self.CoreConnection = CoreGui.DescendantAdded:Connect(function(Descendant)
		if(Descendant:IsA("ScrollingFrame") and Descendant.Name == "ClientLog") then
			task.defer(function() self:Bind(true) end);
		end;
	end);

	task.spawn(function()
		while(self.Alive) do
			self:Bind();
			task.wait(0.25);
		end;
	end);

	return(self);
end;


function RealConsole:Destroy()
	self.Alive	= false;
	if(self.Connection) then self.Connection:Disconnect() end;
	if(self.CoreConn) then self.CoreConn:Disconnect() end;
end;

function RealConsole:Bind(Force)
	local Scroll	= GetClientLogs()
	if(not Scroll) then return(false) end;
	if(not Force and self.Scroll == Scroll and self.Connection and self.Connection.Connected and Scroll:IsDescendantOf(game)) then
		return(true);
	end;

	if(self.Connection) then self.Connection:Disconnect() end;

	self.Scroll		= Scroll;
	self.Connection	= Scroll.DescendantAdded:Connect(function(Descendant)
		if(Descendant:IsA("TextLabel") and Descendant.Name == "msg") then
			local Text = Descendant.Text
			if(not Text) then return end
			for Token, Spec in pairs(self.Tracked) do
				if(string.find(Text, Token, 1, true)) then
					ApplySpec(Descendant, Spec);
					break;
				end;
			end;
		end;
	end);

	for _, Descendant in ipairs(Scroll:GetDescendants()) do
		if(Descendant:IsA("TextLabel") and Descendant.Name == "msg" and Descendant.Text) then
			for Token, Spec in pairs(self.Tracked) do
				if(string.find(Descendant.Text, Token, 1, true)) then
					ApplySpec(Descendant, Spec);
					break;
				end;
			end;
		end;
	end;
	return(true);
end;

function RealConsole:Insert(Lines, Spec)
	self:Bind()
	local Token			= "RC" .. HttpService:GenerateGUID(false):gsub("-", "");
	self.Tracked[Token]	= Spec;
	local Marker		= Token;

	if(Lines and Lines > 1) then Marker = Token .. string.rep("\n", Lines - 1) end;
	LogService:Info(Marker);
	task.defer(function()
		if(not self.Scroll) then return end;
		for _, Descendant in ipairs(self.Scroll:GetDescendants()) do
			if(Descendant:IsA("TextLabel") and Descendant.Name == "msg" and Descendant.Text and string.find(Descendant.Text, Token, 1, true)) then
				ApplySpec(Descendant, Spec);
				break;
			end;
		end;
	end);
	return(Token);
end;

function RealConsole:Text(Kind, Text, FontValue, Size)
	local MessageType	= MessageTypes[Kind];
	local TextColour	= MessageType.Color or MessageTypes.Output.Color;
	local Icon			= MessageType.Icon;

	Size = Size or DefaultMessage.FontSize;

	local Lines = math.max(1, math.ceil(Size / DefaultMessage.LineHeight));
	return(self:Insert(Lines, {
		Apply = function(Row)
			if(Icon) then
				local IconLabel						= Instance.new("ImageLabel");
				IconLabel.Name						= "RC_icon";
				IconLabel.Image						= Icon;
				IconLabel.Size						= UDim2.new(0, DefaultMessage.IconHeight, 0, DefaultMessage.IconHeight);
				IconLabel.Position					= UDim2.new(0, DefaultMessage.IconHeight / 4, 0, (DefaultMessage.FontSize - DefaultMessage.IconHeight) / 2);
				IconLabel.BackgroundTransparency	= 1;
				IconLabel.Parent					= Row;
			end;

			local Label		= Instance.new("TextLabel");
			Label.Name		= "RC_content";
			Label.Text		= tostring(Text);
			Label.RichText	= true;

			ApplyFont(Label, FontValue);

			Label.TextSize					= Size;
			Label.TextColor3				= TextColour;
			Label.TextXAlignment			= Enum.TextXAlignment.Left;
			Label.TextYAlignment			= Enum.TextYAlignment.Top;
			Label.TextWrapped				= true;
			Label.BackgroundTransparency	= 1;
			Label.Size						= UDim2.new(1, -DefaultMessage.ArrowOffset, 1, 0);
			Label.Position					= UDim2.new(0, DefaultMessage.ArrowOffset, 0, 0);
			Label.Parent					= Row;
		end,
	}));
end;

function RealConsole:Output(Text, FontValue, Size) return(self:Text("Output", Text, FontValue, Size)) end;
function RealConsole:Print(Text, FontValue, Size) return(self:Text("Output", Text, FontValue, Size)) end;
function RealConsole:Info(Text, FontValue, Size) return(self:Text("Info", Text, FontValue, Size)) end;
function RealConsole:Warn(Text, FontValue, Size) return(self:Text("Warn", Text, FontValue, Size)) end;
function RealConsole:Error(Text, FontValue, Size) return(self:Text("Error", Text, FontValue, Size)) end;

function RealConsole:Image(Image, Height)
	Height	= Height or 96;
	local Pad		= 8;
	local Lines		= math.max(1, math.ceil((Height + Pad * 2) / DefaultMessage.LineHeight));
	local Source	= type(Image) == "number" and ("rbxassetid://" .. Image) or tostring(Image);
	return(self:Insert(Lines, {
		Apply = function(Row)
			local ImageLabel					= Instance.new("ImageLabel");
			ImageLabel.Name						= "RC_content";
			ImageLabel.Image					= Source;
			ImageLabel.Size						= UDim2.new(0, Height, 0, Height);
			ImageLabel.Position					= UDim2.new(0, DefaultMessage.ArrowOffset, 0, Pad);
			ImageLabel.BackgroundTransparency	= 1;
			ImageLabel.ScaleType				= Enum.ScaleType.Fit;
			ImageLabel.Parent					= Row;
		end,
	}));
end;

function RealConsole:Banner(Image, Text, Height, TextColour, FontValue)
	Height	= Height or 64
	local Pad				= 8
	local Lines				= math.max(1, math.ceil((Height + Pad * 2) / DefaultMessage.LineHeight));
	local Source			= type(Image) == "number" and ("rbxassetid://" .. Image) or tostring(Image);
	local BannerTextSize	= math.floor(Height * 0.75);
	local BannerColour		= TextColour or Color3.fromRGB(255, 255, 255);

	return(self:Insert(Lines, {
		Apply = function(Row)
			local Holder					= Instance.new("Frame");
			Holder.Name						= "RC_content";
			Holder.BackgroundTransparency	= 1;
			Holder.Size						= UDim2.new(1, -DefaultMessage.ArrowOffset, 0, Height);
			Holder.Position					= UDim2.new(0, DefaultMessage.ArrowOffset, 0, Pad);

			local ImageLabel					= Instance.new("ImageLabel");
			ImageLabel.Name						= "Image";
			ImageLabel.Image					= Source;
			ImageLabel.Size 					= UDim2.new(0, Height, 0, Height);
			ImageLabel.Position					= UDim2.new(0, 0, 0, 0);
			ImageLabel.BackgroundTransparency	= 1;
			ImageLabel.ScaleType				= Enum.ScaleType.Fit;
			ImageLabel.Parent					= Holder;

			local Label		= Instance.new("TextLabel");
			Label.Name		= "Text";
			Label.Text		= tostring(Text);
			Label.RichText	= true;

			if(FontValue) then ApplyFont(Label, FontValue) else Label.Font = Enum.Font.GothamBold end;

			Label.TextSize					= BannerTextSize;
			Label.TextColor3				= BannerColour;
			Label.TextXAlignment 			= Enum.TextXAlignment.Left;
			Label.TextYAlignment 			= Enum.TextYAlignment.Center;
			Label.TextWrapped				= false;
			Label.BackgroundTransparency	= 1;
			Label.Size						= UDim2.new(1, -(Height + 12), 1, 0);
			Label.Position					= UDim2.new(0, Height + 12, 0, 0);
			Label.Parent					= Holder;

			Holder.Parent	= Row;
		end,
	}));
end;

function RealConsole:Custom(Content, Height)
	Height	= Height or 32;
	local Lines	= math.max(1, math.ceil(Height / DefaultMessage.LineHeight));
	return(self:Inject(Lines, {
		Apply = function(Row)
			if(type(Content) == "function") then
				local Made	= Content(Row);
				if(typeof(Made) == "Instance") then
					Made.Name	= "RC_content";
					Made.Parent	= Row;
				end
			elseif(typeof(Content) == "Instance") then
				local Clone		= Content:Clone();
				Clone.Name		= "RC_content";
				Clone.Position	= UDim2.new(0, DefaultMessage.ArrowOffset, 0, 0);
				Clone.Parent	= Row;
			end;
		end,
	}));
end;

function RealConsole:OpenConsole()
	if(IsConsoleVisible()) then
		self:Bind();
		return(self);
	end;
	VirtualInput:SendKeyEvent(true, Enum.KeyCode.F9, false, game);
	task.wait();
	VirtualInput:SendKeyEvent(false, Enum.KeyCode.F9, false, game);

	task.delay(0.25, function() self:Bind(true) end);
	return(self);
end;

--? Doesnt work yet...
function RealConsole:Clear()
	self.Tracked = {};
	pcall(function() LogService:ClearOutput() end);
	return(self);
end;

return RealConsole.New();
