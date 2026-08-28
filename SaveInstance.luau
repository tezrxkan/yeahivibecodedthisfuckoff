--[[
    SaveInstance v2
    28/08/2026
    Improved version with more class support, property types, attributes, file export, and better error handling.

    Exports the instance(s) into a rblx format and copies to clipboard or saves to file.
]]

local DEFAULT_CONFIG = {
    root = game,

    includeServices = nil,
    excludeServices = nil,

    includeClassNames = nil,
    excludeClassNames = nil,

    includeNames = nil,
    excludeNames = nil,

    includeNamePatterns = nil,
    excludeNamePatterns = nil,

    includeChildrenOfFiltered = false,
    decompileScripts = false,
    excludePlayers = true,
    showConsole = true,

    exportAttributes = true,
    saveToFile = false,
    fileName = nil,
}

_G.CONFIG = _G.CONFIG or DEFAULT_CONFIG

local Workspace = game:GetService('Workspace')
local Players = game:GetService('Players')
local Camera = Workspace.CurrentCamera

local PLAYER_NAME_SET = nil

local KNOWN_PROPERTIES = {
    Workspace = {
        'CurrentCamera', 'DistributedGameTime', 'Name', 'Parent', 'UniqueId',
        'AllowThirdPartySales', 'ClientAnimatorThrottling', 'FallenPartsDestroyHeight',
        'GlobalWind', 'Gravity', 'PhysicsSteppingMethod', 'StreamingEnabled',
        'SignalBehavior', 'TouchesUseCollisionGroups', 'AirDensity',
        'RejectCharacterDeletions', 'LuauTypeCheckMode',
    },

    Camera = {
        'CFrame', 'Focus', 'HeadLocked', 'HeadScale', 'Name', 'NearPlaneZ', 'Parent',
        'UniqueId', 'ViewportSize', 'VRTiltAndRollEnabled', 'Origin', 'PivotOffset',
        'CameraSubject', 'CameraType', 'DiagonalFieldOfView', 'FieldOfView',
        'FieldOfViewMode', 'MaxAxisFieldOfView', 'Archivable',
    },

    Terrain = {
        'Decoration', 'GrassLength', 'MaterialColors', 'WaterColor', 'WaterReflectance',
        'WaterTransparency', 'WaterWaveSize', 'WaterWaveSpeed', 'Archivable', 'Name',
        'Parent', 'UniqueId', 'CollisionGroup', 'CustomPhysicalProperties',
    },

    Model = {
        'LevelOfDetail', 'Archivable', 'Name', 'Parent', 'UniqueId', 'Origin',
        'PrimaryPart', 'Scale', 'WorldPivot',
    },

    Part = {
        'BrickColor', 'CastShadow', 'Color', 'Material', 'MaterialVariant',
        'Reflectance', 'Transparency', 'Archivable', 'Locked', 'Name', 'Parent',
        'UniqueId', 'Size', 'CFrame', 'CanCollide', 'CanTouch', 'CollisionGroup',
        'Anchored', 'CustomPhysicalProperties', 'Massless', 'Shape',
        'BackSurface', 'BottomSurface', 'FrontSurface', 'LeftSurface',
        'RightSurface', 'TopSurface', 'RootPriority',
    },

    MeshPart = {
        'BrickColor', 'CastShadow', 'Color', 'DoubleSided', 'Material',
        'MaterialVariant', 'MeshContent', 'MeshId', 'Reflectance', 'RenderFidelity',
        'TextureContent', 'TextureID', 'Transparency', 'Archivable', 'Locked',
        'MeshSize', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame',
        'CanCollide', 'CanTouch', 'CollisionGroup', 'Anchored', 'Massless',
        'CollisionFidelity', 'FluidFidelity', 'RootPriority',
    },

    TrussPart = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'Style',
    },

    CornerWedgePart = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'Anchored',
        'CanCollide', 'Massless',
    },

    WedgePart = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'Anchored',
        'CanCollide', 'Massless',
    },

    SpawnLocation = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'Anchored',
        'CanCollide', 'Duration', 'Neutral', 'AllowTeamChangeOnTouch',
        'TeamColor', 'TopSurface', 'BottomSurface',
    },

    Humanoid = {
        'Archivable', 'CameraOffset', 'DisplayDistanceType', 'DisplayName',
        'HealthDisplayDistance', 'HealthDisplayType', 'Name', 'NameDisplayDistance',
        'NameOcclusion', 'Parent', 'RigType', 'UniqueId', 'BreakJointsOnDeath',
        'EvaluateStateMachine', 'RequiresNeck', 'AutoRotate', 'FloorMaterial',
        'HipHeight', 'MaxHealth', 'MaxSlopeAngle', 'WalkSpeed', 'AutoJumpEnabled',
        'JumpPower', 'UseJumpPower', 'Health', 'WalkToPart', 'WalkToPoint',
        'AutomaticScalingEnabled', 'DisplayDistanceType',
    },

    Accessory = {
        'Archivable', 'AccessoryType', 'ClassName', 'Name', 'Parent', 'UniqueId',
        'AttachmentPoint',
    },

    Hat = {
        'Archivable', 'ClassName', 'Name', 'Parent', 'UniqueId',
        'AttachmentForward', 'AttachmentPoint', 'AttachmentPos', 'AttachmentRight',
        'AttachmentUp',
    },

    BodyColors = {
        'HeadColor', 'HeadColor3', 'LeftArmColor', 'LeftArmColor3',
        'LeftLegColor', 'LeftLegColor3', 'RightArmColor', 'RightArmColor3',
        'RightLegColor', 'RightLegColor3', 'TorsoColor', 'TorsoColor3',
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    Pants = {
        'PantsTemplate', 'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    Shirt = {
        'ShirtTemplate', 'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    ShirtGraphic = {
        'Graphic', 'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    ShirtGraphic = {
        'Graphic', 'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    LocalScript = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled',
    },

    Script = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled',
    },

    ModuleScript = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled',
    },

    NumberValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    StringValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    IntValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    BoolValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    ObjectValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    Vector3Value = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    Vector2Value = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    Color3Value = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    CFrameValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    UDimValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    UDim2Value = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    NumberSequenceValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    ColorSequenceValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    NumberRangeValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    RayValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    RectValue = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Value',
    },

    BriskForce = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Force', 'ForceLimitsEnabled',
        'MaxForce', 'MinForce',
    },

    BodyVelocity = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'MaxForce', 'P', 'Velocity',
    },

    BodyAngularVelocity = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'AngularVelocity', 'MaxTorque', 'P',
    },

    BodyPosition = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'MaxForce', 'Position', 'P', 'D',
    },

    BodyGyro = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'CFrame', 'D', 'MaxTorque', 'P',
    },

    BodyThrust = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Force', 'Location', 'P',
    },

    Attachment = {
        'Visible', 'Archivable', 'Name', 'Parent', 'UniqueId', 'CFrame',
        'Axis', 'SecondaryAxis', 'WorldCFrame', 'WorldAxis', 'WorldSecondaryAxis',
    },

    Weld = {
        'Archivable', 'C0', 'C1', 'Name', 'Parent', 'Part0', 'Part1', 'UniqueId',
        'Enabled',
    },

    Motor6D = {
        'Archivable', 'C0', 'C1', 'Transform', 'Name', 'Parent', 'Part0', 'Part1',
        'UniqueId', 'Enabled',
    },

    WeldConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled',
    },

    ManualWeld = {
        'Archivable', 'C0', 'C1', 'Name', 'Parent', 'Part0', 'Part1', 'UniqueId',
    },

    Snap = {
        'Archivable', 'C0', 'C1', 'Name', 'Parent', 'Part0', 'Part1', 'UniqueId',
        'Enabled',
    },

    RopeConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Length',
        'Restitution', 'Visible', 'Attachment0', 'Attachment1', 'Color',
    },

    HingeConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'LimitsEnabled',
        'LowerAngle', 'UpperAngle', 'ActuatorType', 'AngularVelocity', 'Torque',
        'Attachment0', 'Attachment1',
    },

    BallSocketConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'LimitsEnabled',
        'UpperAngle', 'TwistLimitsEnabled', 'TwistLowerAngle', 'TwistUpperAngle',
        'Attachment0', 'Attachment1',
    },

    PrismaticConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'LimitsEnabled',
        'LowerLimit', 'UpperLimit', 'Restitution', 'ActuatorType', 'Velocity',
        'Force', 'Attachment0', 'Attachment1',
    },

    RopeConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Length',
        'Restitution', 'Visible', 'Attachment0', 'Attachment1',
    },

    SpringConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Coils',
        'Damping', 'FreeLength', 'LimitsEnabled', 'MaxForce', 'MaxVelocity',
        'MinLength', 'Radius', 'Stiffness', 'Visible',
        'Attachment0', 'Attachment1',
    },

    VectorForce = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Force',
        'RelativeTo', 'ApplyAtCenterOfMass',
        'Attachment0', 'Attachment1',
    },

    Torque = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Torque',
        'RelativeTo', 'Attachment0', 'Attachment1',
    },

    LineForce = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Force',
        'InverseSquareLaw', 'MaxForce', 'MinForce',
        'Attachment0', 'Attachment1',
    },

    Beam = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Color',
        'LightEmission', 'LightInfluence', 'Texture', 'TextureLength',
        'TextureSpeed', 'TextureStudsPerUnit', 'Transparency', 'Width0', 'Width1',
        'CurveSize0', 'CurveSize1', 'FaceCamera', 'Segments', 'Capped',
        'Attachment0', 'Attachment1',
    },

    Trail = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Color',
        'FaceCamera', 'LightEmission', 'LightInfluence', 'Lifetime',
        'MaxLength', 'MinLength', 'Texture', 'TextureLength', 'TextureMode',
        'TextureSpeed', 'TextureStudsPerUnit', 'Transparency', 'WidthScale',
        'Attachment0', 'Attachment1',
    },

    Fire = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Color',
        'Enabled', 'Heat', 'LightEmission', 'LightInfluence', 'Size',
        'SecondaryColor', 'TimeScale',
    },

    Smoke = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Color', 'Enabled',
        'LightEmission', 'LightInfluence', 'Opacity', 'RiseVelocity', 'Size',
        'TimeScale',
    },

    Sparkles = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled',
    },

    Explosion = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BlastPressure',
        'BlastRadius', 'DestroyJointRadiusPercent', 'ExplosionType',
        'Position', 'Visible',
    },

    Sound = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'PlayOnRemove', 'IsLoaded',
        'TimeLength', 'RollOffMaxDistance', 'RollOffMinDistance', 'RollOffMode',
        'Looped', 'PlaybackSpeed', 'Playing', 'TimePosition', 'Volume',
        'SoundGroup', 'SoundId',
    },

    SoundGroup = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Volume',
    },

    Atmospheric = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Density',
        'Haze', 'Glare', 'Decay', 'Color', 'MoonAngularSize', 'SunAngularSize',
    },

    BloomEffect = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Intensity',
        'Size', 'Threshold',
    },

    BlurEffect = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Size',
    },

    ColorCorrectionEffect = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Brightness',
        'Contrast', 'Saturation', 'TintColor',
    },

    ColorGradingEffect = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'TonemapperPreset',
    },

    DepthOfFieldEffect = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'FarIntensity',
        'FocusDistance', 'InFocusRadius', 'NearIntensity',
    },

    SunRaysEffect = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Intensity',
        'Spread',
    },

    SurfaceLight = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Brightness',
        'Color', 'Shadows', 'Range', 'Angle', 'Face', 'Face',
    },

    PointLight = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Brightness',
        'Color', 'Shadows', 'Range',
    },

    SpotLight = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Brightness',
        'Color', 'Shadows', 'Range', 'Angle', 'Face',
    },

    SurfaceGui = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Active',
        'Adornee', 'CanvasSize', 'Face', 'LightInfluence', 'PixelsPerStud',
        'SizingMode', 'ToolPunchThrough', 'ZOffset',
    },

    ScreenGui = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Active',
        'DisplayOrder', 'IgnoreGuiInset', 'ResetOnSpawn', 'ZIndexBehavior',
    },

    BillboardGui = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Active',
        'Adornee', 'AlwaysOnTop', 'LightInfluence', 'MaxDistance',
        'Size', 'SizeOffset', 'StudsOffset', 'StudsOffsetWorldSpace', 'ZOffset',
    },

    Frame = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'ClipsDescendants', 'Size', 'Position', 'AnchorPoint', 'Rotation',
        'Visible', 'ZIndex', 'LayoutOrder', 'Style',
    },

    ScrollingFrame = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'ClipsDescendants', 'Size', 'Position', 'AnchorPoint', 'Rotation',
        'Visible', 'ZIndex', 'LayoutOrder', 'AutomaticCanvasSize',
        'BottomImage', 'CanvasPosition', 'CanvasSize', 'HorizontalScrollBarInset',
        'MidImage', 'ScrollBarImageColor3', 'ScrollBarImageTransparency',
        'ScrollBarThickness', 'ScrollingDirection', 'ScrollingEnabled',
        'TopImage', 'VerticalScrollBarInset', 'VerticalScrollBarPosition',
    },

    TextLabel = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'Size', 'Position', 'AnchorPoint', 'Rotation', 'Visible', 'ZIndex',
        'LayoutOrder', 'Text', 'TextColor3', 'TextTransparency', 'TextScaled',
        'TextSize', 'TextWrapped', 'TextXAlignment', 'TextYAlignment',
        'Font', 'RichText',
    },

    TextButton = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'Size', 'Position', 'AnchorPoint', 'Rotation', 'Visible', 'ZIndex',
        'LayoutOrder', 'Text', 'TextColor3', 'TextTransparency', 'TextScaled',
        'TextSize', 'TextWrapped', 'TextXAlignment', 'TextYAlignment',
        'Font', 'AutoButtonColor', 'Modal', 'Style', 'RichText',
    },

    TextBox = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'Size', 'Position', 'AnchorPoint', 'Rotation', 'Visible', 'ZIndex',
        'LayoutOrder', 'Text', 'TextColor3', 'TextTransparency', 'TextScaled',
        'TextSize', 'TextWrapped', 'TextXAlignment', 'TextYAlignment',
        'Font', 'ClearTextOnFocus', 'MultiLine', 'PlaceholderColor3',
        'PlaceholderText', 'ShowNativeInput', 'TextEditable', 'CursorPosition',
        'SelectionStart', 'RichText',
    },

    ImageLabel = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'Size', 'Position', 'AnchorPoint', 'Rotation', 'Visible', 'ZIndex',
        'LayoutOrder', 'Image', 'ImageColor3', 'ImageRectOffset',
        'ImageRectSize', 'ImageTransparency', 'ScaleType', 'SliceCenter',
        'TileSize',
    },

    ImageButton = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BackgroundColor3',
        'BackgroundTransparency', 'BorderColor3', 'BorderMode', 'BorderSizePixel',
        'Size', 'Position', 'AnchorPoint', 'Rotation', 'Visible', 'ZIndex',
        'LayoutOrder', 'Image', 'ImageColor3', 'ImageRectOffset',
        'ImageRectSize', 'ImageTransparency', 'ScaleType', 'SliceCenter',
        'TileSize', 'AutoButtonColor', 'Modal', 'Style',
    },

    UIListLayout = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'FillDirection',
        'HorizontalAlignment', 'VerticalAlignment', 'SortOrder', 'Padding',
        'Wraps',
    },

    UIGridLayout = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'CellPadding',
        'CellSize', 'FillDirectionMaxCells', 'HorizontalAlignment',
        'SortOrder', 'VerticalAlignment',
    },

    UIPadding = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'PaddingBottom',
        'PaddingLeft', 'PaddingRight', 'PaddingTop',
    },

    UIAspectRatioConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'AspectRatio',
        'AspectType', 'DominantAxis',
    },

    UISizeConstraint = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'MaxSize', 'MinSize',
    },

    UIScale = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Scale',
    },

    UICorner = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'CornerRadius',
    },

    UIStroke = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'ApplyStrokeMode',
        'Color', 'LineJoinMode', 'Thickness', 'Transparency', 'Enabled',
    },

    UIGradient = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Color', 'Enabled',
        'Offset', 'Rotation', 'Transparency',
    },

    Decal = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Color3', 'Face',
        'Texture', 'Transparency', 'ZIndex',
    },

    Texture = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Color3', 'Face',
        'StudsPerTileU', 'StudsPerTileV', 'Texture', 'Transparency', 'ZIndex',
    },

    ParticleEmitter = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Color', 'Drag',
        'EmissionDirection', 'Enabled', 'Lifetime', 'LightEmission',
        'LightInfluence', 'LockedToPart', 'Rate', 'RotSpeed', 'Rotation',
        'Shape', 'ShapeInOut', 'ShapeOutline', 'ShapePartial', 'ShapeStyle',
        'Size', 'Speed', 'SpreadAngle', 'Squash', 'Texture', 'TimeScale',
        'Transparency', 'VelocityInheritance', 'ZOffset',
    },

    SpecialMesh = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'MeshType', 'MeshId',
        'Scale', 'TextureId', 'Offset',
    },

    BlockMesh = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Scale', 'TextureId', 'Offset',
    },

    CylinderMesh = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Scale', 'TextureId', 'Offset',
    },

    CharacterMesh = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'BodyPart', 'MeshId',
        'OverlayTextureId', 'RigType', 'Scale',
    },

    SurfaceAppearance = {
        'AlphaMode', 'ColorMap', 'MetalnessMap', 'NormalMap', 'RoughnessMap',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'ColorMap', 'MetalnessMap',
        'NormalMap', 'RoughnessMap',
    },

    WrapLayer = {
        'CageMeshContent', 'CageMeshId', 'CageOrigin', 'ImportOrigin', 'Order',
        'Puffiness', 'ReferenceMeshContent', 'ReferenceMeshId', 'ReferenceOrigin',
        'Archivable', 'CageOriginWorld', 'ImportOriginWorld', 'Name', 'Parent',
        'ReferenceOriginWorld', 'UniqueId', 'AutoSkin', 'Enabled', 'Color',
        'DebugMode', 'BindOffset', 'ShrinkFactor',
    },

    WrapTarget = {
        'CageMeshContent', 'CageMeshId', 'CageOrigin', 'ImportOrigin',
        'Archivable', 'CageOriginWorld', 'ImportOriginWorld', 'Name', 'Parent',
        'UniqueId', 'Color', 'DebugMode',
    },

    DataStoreMapping = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    Configuration = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    Folder = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    BindableEvent = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    BindableFunction = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    RemoteEvent = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    RemoteFunction = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    TweenBase = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    Tween = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    ClickDetector = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'MaxActivationDistance',
    },

    ProximityPrompt = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'ActionText', 'Enabled',
        'GamepadKeyCode', 'HoldDuration', 'KeyboardKeyCode', 'MaxActivationDistance',
        'ObjectText', 'RequiresLineOfSight', 'SingleAction',
    },

    Highlight = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'Enabled',
        'FillColor', 'FillTransparency', 'OutlineColor', 'OutlineTransparency',
    },

    SelectionBox = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'Color3',
        'Enabled', 'LineThickness', 'SurfaceColor3', 'SurfaceTransparency',
        'Surfaces', 'Transparency', 'Visible',
    },

    SelectionSphere = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'Color3',
        'Enabled', 'SurfaceColor3', 'SurfaceTransparency', 'Surfaces',
        'Transparency', 'Visible',
    },

    BoxHandleAdornment = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'AlwaysOnTop',
        'Color3', 'Size', 'Transparency', 'ZIndex',
    },

    SphereHandleAdornment = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'AlwaysOnTop',
        'Color3', 'Radius', 'Transparency', 'ZIndex',
    },

    CylinderHandleAdornment = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'AlwaysOnTop',
        'Color3', 'Height', 'Radius', 'Transparency', 'ZIndex',
    },

    WireframeHandleAdornment = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Adornee', 'AlwaysOnTop',
        'Color3', 'Size', 'Transparency', 'ZIndex',
    },

    SurfaceGui = {
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Enabled', 'Active',
        'Adornee', 'CanvasSize', 'Face', 'LightInfluence', 'PixelsPerStud',
        'SizingMode', 'ToolPunchThrough', 'ZOffset',
    },

    DynamicRotationCylinder = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    DynamicRotationPart = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    Seat = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'Anchored',
        'CanCollide', 'Disabled', 'Shape',
    },

    VehicleSeat = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'Anchored',
        'CanCollide', 'Disabled', 'HeadsUpDisplay', 'MaxSpeed', 'Torque',
        'TurnSpeed', 'Speed',
    },

    SkinnedMeshPart = {
        'BrickColor', 'Color', 'Material', 'Transparency', 'Reflectance',
        'Archivable', 'Name', 'Parent', 'UniqueId', 'Size', 'CFrame', 'MeshId',
        'TextureID', 'DoubleSided', 'RenderFidelity',
    },

    CollisionGroup = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },

    GuiService = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
    },
}

local CONTENT_PROPS_BY_CLASSNAME = {
    MeshPart = { 'MeshId', 'TextureID', 'TextureId', 'MeshContent', 'TextureContent' },
    SpecialMesh = { 'MeshId', 'TextureId' },
    BlockMesh = { 'TextureId' },
    CylinderMesh = { 'TextureId' },
    SurfaceAppearance = { 'ColorMap', 'NormalMap', 'RoughnessMap', 'MetalnessMap' },
    ShirtGraphic = { 'Graphic' },
    ImageButton = { 'Image' },
    ImageLabel = { 'Image' },
    CharacterMesh = { 'MeshId', 'OverlayTextureId' },
    Sound = { 'SoundId', 'AudioContent' },
    Decal = { 'Texture' },
    Texture = { 'Texture' },
    ParticleEmitter = { 'Texture' },
    Beam = { 'Texture' },
    Trail = { 'Texture' },
}

local BASE_PART_WRITE_PROPS = {
    CFrame = true,
    Size = true,
    Anchored = true,
    CanCollide = true,
    CanQuery = true,
    CanTouch = true,
    Massless = true,
    CastShadow = true,
    Locked = true,
    Transparency = true,
    Reflectance = true,
    Color = true,
    BrickColor = true,
    Material = true,
    CollisionGroupId = true,
    Velocity = true,
    AssemblyLinearVelocity = true,
}

local CLASS_HANDLERS = {}
local VALUE_BASE_HANDLERS = {}


local function createProgressBar()
    local width = 380
    local height = 18
    local yPad = 48

    local panel = Drawing.new('Square')
    panel.Filled = true
    panel.Thickness = 1
    panel.Color = Color3.new(0, 0, 0)
    panel.Transparency = 0.75
    panel.Visible = true

    local outline = Drawing.new('Square')
    outline.Filled = false
    outline.Thickness = 1
    outline.Color = Color3.new(1, 1, 1)
    outline.Visible = true

    local back = Drawing.new('Square')
    back.Filled = true
    back.Thickness = 1
    back.Color = Color3.new(0, 0, 0)
    back.Transparency = 0.55
    back.Visible = true

    local fill = Drawing.new('Square')
    fill.Filled = true
    fill.Thickness = 1
    fill.Color = Color3.new(0.2, 0.8, 0.35)
    fill.Transparency = 1
    fill.Visible = true

    local label = Drawing.new('Text')
    label.Size = 13
    label.Center = true
    label.Outline = true
    label.Color = Color3.new(1, 1, 1)
    label.Visible = true

    local function safeDestroy(obj)
        if obj then
            obj:Remove()
        end
    end

    local TEXT_Y_OFFSET = 6

    local function setLayout()
        local vp = Camera.ViewportSize
        local x = (vp.X / 2) - (width / 2)
        local y = yPad

        panel.Position = Vector2.new(x - 6, y - 6)
        panel.Size = Vector2.new(width + 12, height + 12)

        outline.Position = Vector2.new(x, y)
        outline.Size = Vector2.new(width, height)
        back.Position = Vector2.new(x + 1, y + 1)
        back.Size = Vector2.new(width - 2, height - 2)

        label.Position = Vector2.new(vp.X / 2, y + (height / 2) - (label.Size / 2) + TEXT_Y_OFFSET)
        return x, y
    end

    local x0, y0 = setLayout()

    return {
        update = function(current, total, text)
            local vp = Camera.ViewportSize
            local desiredX = (vp.X / 2) - (width / 2)
            if desiredX ~= x0 then
                x0, y0 = setLayout()
            end

            local pct = 0
            if type(total) == 'number' and total > 0 then
                pct = math.max(0, math.min(1, (current or 0) / total))
            end

            fill.Position = Vector2.new(x0 + 2, y0 + 2)
            fill.Size = Vector2.new(math.floor((width - 4) * pct), height - 4)

            if text then
                label.Text = text
            else
                label.Text = string.format('%d/%d (%.1f%%)', current or 0, total or 0, pct * 100)
            end
        end,
        destroy = function()
            safeDestroy(panel)
            safeDestroy(outline)
            safeDestroy(back)
            safeDestroy(fill)
            safeDestroy(label)
        end,
    }
end

local function createMiniConsole()
    local width = 520
    local lineHeight = 16
    local lines = 7
    local pad = 8

    local panel = Drawing.new('Square')
    panel.Filled = true
    panel.Thickness = 1
    panel.Color = Color3.new(0, 0, 0)
    panel.Transparency = 0.65
    panel.Visible = true
    panel.ZIndex = 100

    local outline = Drawing.new('Square')
    outline.Filled = false
    outline.Thickness = 1
    outline.Color = Color3.new(1, 1, 1)
    outline.Visible = true
    outline.ZIndex = 101

    local textLines = {}
    for i = 1, lines do
        local t = Drawing.new('Text')
        t.Size = 13
        t.Center = false
        t.Outline = true
        t.Color = Color3.new(1, 1, 1)
        t.Visible = true
        t.ZIndex = 102
        textLines[i] = t
    end

    local function safeDestroy(obj)
        if obj then
            obj:Remove()
        end
    end

    local function setLayout()
        local vp = Camera.ViewportSize
        local height = (lines * lineHeight) + (pad * 2)
        local x = 10
        local y = vp.Y - height - 10
        if vp.Y == nil or vp.Y < (height + 20) then
            y = 10
        end
        if vp.X ~= nil and vp.X < (width + 20) then
            x = 10
        end

        panel.Position = Vector2.new(x, y)
        panel.Size = Vector2.new(width, height)

        outline.Position = Vector2.new(x, y)
        outline.Size = Vector2.new(width, height)

        for i, t in ipairs(textLines) do
            t.Position = Vector2.new(x + pad, y + pad + ((i - 1) * lineHeight))
        end
    end

    setLayout()

    local entries = {}
    local counter = 0

    local function clipText(text)
        text = tostring(text or '')
        local fontSize = textLines[1] and textLines[1].Size or 13
        local approxCharWidth = fontSize * 0.6
        local safety = 14
        local maxChars = math.floor((width - (pad * 2) - safety) / approxCharWidth)
        if maxChars < 5 then
            return text
        end
        if #text > maxChars then
            return text:sub(1, maxChars - 3) .. '...'
        end
        return text
    end

    local function refresh()
        setLayout()
        for i = 1, lines do
            local idx = #entries - lines + i
            local text = entries[idx] or ''
            textLines[i].Text = clipText(text)
        end
    end

    return {
        log = function(text)
            counter = counter + 1
            entries[#entries + 1] = string.format('#%d %s', counter, text)
            refresh()
        end,
        setCurrent = function(text)
            counter = counter + 1
            entries[#entries + 1] = string.format('#%d %s', counter, text)
            refresh()
        end,
        done = function(text)
            counter = counter + 1
            entries[#entries + 1] = string.format('#%d %s', counter, text)
            refresh()
        end,
        destroy = function()
            safeDestroy(panel)
            safeDestroy(outline)
            for _, t in ipairs(textLines) do
                safeDestroy(t)
            end
        end,
    }
end

local function xmlEscape(value)
    local s = tostring(value)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    s = s:gsub("'", "&apos;")
    return s
end

local function safeGet(inst, prop)
    local ok, v = pcall(function()
        return inst[prop]
    end)
    if ok then
        return v
    end
    return nil
end

local function buildPlayerNameSet()
    if not _G.CONFIG.excludePlayers then
        return nil
    end
    local set = {}
    local localPlayer = safeGet(Players, 'LocalPlayer')
    if localPlayer then
        local lpName = safeGet(localPlayer, 'Name')
        if type(lpName) == 'string' then
            set[lpName] = true
        end
    end
    local ok, list = pcall(function()
        return Players:GetPlayers()
    end)
    if ok and type(list) == 'table' then
        for _, player in ipairs(list) do
            local name = safeGet(player, 'Name')
            if type(name) == 'string' then
                set[name] = true
            end
        end
    end
    return set
end

local function tryDecompileScript(inst)
    if not _G.CONFIG.decompileScripts then
        return nil
    end
    local className = inst.ClassName
    if className ~= 'LocalScript' and className ~= 'ModuleScript' and className ~= 'Script' then
        return nil
    end
    local maxAttempts = 10
    for attempt = 1, maxAttempts do
        local ok, src = pcall(decompile, inst)
        if ok and type(src) == 'string' and src ~= '' then
            if string.find(src, 'Unable to fetch', 1, true) or string.find(src, 'decode', 1, true) then
                -- retry
            else
                return src
            end
        else
            return 'Decompile failed'
        end

        if attempt < maxAttempts then
            task.wait(0.1)
        end
    end
    return nil
end

local function nameMatchesPatterns(name, patterns)
    if type(patterns) ~= 'table' then
        return false
    end
    for _, pattern in ipairs(patterns) do
        if type(pattern) == 'string' and string.match(name, pattern) then
            return true
        end
    end
    return false
end

local function shouldExportInstance(inst)
    local className = inst.ClassName
    if _G.CONFIG.excludeClassNames and _G.CONFIG.excludeClassNames[className] then
        return false
    end
    if _G.CONFIG.includeClassNames and not _G.CONFIG.includeClassNames[className] then
        return false
    end

    local name = safeGet(inst, 'Name')
    if type(name) == 'string' then
        if _G.CONFIG.excludePlayers and className == 'Model' and PLAYER_NAME_SET and PLAYER_NAME_SET[name] then
            local okDesc = pcall(function()
                return inst:IsDescendantOf(Workspace)
            end)
            if okDesc then
                return false
            end
        end
        if _G.CONFIG.excludeNames and _G.CONFIG.excludeNames[name] then
            return false
        end
        if _G.CONFIG.includeNames and not _G.CONFIG.includeNames[name] then
            return false
        end
        if _G.CONFIG.excludeNamePatterns and nameMatchesPatterns(name, _G.CONFIG.excludeNamePatterns) then
            return false
        end
        if _G.CONFIG.includeNamePatterns and not nameMatchesPatterns(name, _G.CONFIG.includeNamePatterns) then
            return false
        end
    end

    return true
end

local function shouldExportService(inst)
    local name = safeGet(inst, 'Name')
    if type(name) ~= 'string' then
        return true
    end
    if _G.CONFIG.excludePlayers and name == 'Players' then
        return false
    end
    if _G.CONFIG.excludeServices and _G.CONFIG.excludeServices[name] then
        return false
    end
    if _G.CONFIG.includeServices and not _G.CONFIG.includeServices[name] then
        return false
    end
    return true
end

local function push(out, s)
    out[#out + 1] = s
end

local function writeTag(out, tagName, attrs, inner)
    if attrs then
        local keys = {}
        for k in pairs(attrs) do
            keys[#keys + 1] = k
        end
        table.sort(keys)
        local buf = { "<", tagName }
        for _, k in ipairs(keys) do
            local v = attrs[k]
            if v ~= nil then
                buf[#buf + 1] = " "
                buf[#buf + 1] = k
                buf[#buf + 1] = "=\""
                buf[#buf + 1] = xmlEscape(v)
                buf[#buf + 1] = "\""
            end
        end
        buf[#buf + 1] = ">"
        push(out, table.concat(buf))
    else
        push(out, "<" .. tagName .. ">")
    end

    if inner ~= nil then
        push(out, inner)
    end

    push(out, "</" .. tagName .. ">")
end

local function writeBool(out, name, v)
    writeTag(out, 'bool', { name = name }, v and 'true' or 'false')
end

local function writeInt(out, name, v)
    writeTag(out, 'int', { name = name }, tostring(v))
end

local function writeFloat(out, name, v)
    writeTag(out, 'float', { name = name }, tostring(v))
end

local function writeDouble(out, name, v)
    writeTag(out, 'double', { name = name }, tostring(v))
end

local function writeString(out, name, v)
    writeTag(out, 'string', { name = name }, xmlEscape(v))
end

local INVALID_URL_PATTERNS = {
    'failed', 'error', 'nil', 'unable', 'could not', 'cannot',
    'not found', 'invalid', 'empty', 'null',
}

local function isValidAssetUrl(s)
    if type(s) ~= 'string' or s == '' then
        return false
    end
    local lower = s:lower()
    for _, pat in ipairs(INVALID_URL_PATTERNS) do
        if lower:find(pat, 1, true) then
            return false
        end
    end
    if s:find('^%d+$') then
        return true
    end
    if s:find('rbxasset', 1, true) then
        return true
    end
    if s:find('http://', 1, true) or s:find('https://', 1, true) then
        return true
    end
    return false
end

local function normalizeAssetUrl(v)
    if v == nil then
        return nil
    end

    local t = type(v)
    if t == 'string' then
        if v == '' then
            return nil
        end
        if isValidAssetUrl(v) then
            if v:find('rbxasset', 1, true) or v:find('http://', 1, true) or v:find('https://', 1, true) then
                return v
            end
            local num = tonumber(v)
            if num then
                return 'rbxassetid://' .. tostring(math.floor(num))
            end
        end
        return nil
    end

    if t == 'number' then
        return 'rbxassetid://' .. tostring(math.floor(v))
    end

    if t == 'userdata' then
        local uri = safeGet(v, 'Uri') or safeGet(v, 'URI') or safeGet(v, 'uri')
        if uri ~= nil then
            return normalizeAssetUrl(uri)
        end

        local value = safeGet(v, 'Value') or safeGet(v, 'value')
        if value ~= nil then
            return normalizeAssetUrl(value)
        end

        local id = safeGet(v, 'Id') or safeGet(v, 'id')
        if id ~= nil then
            return normalizeAssetUrl(id)
        end

        local assetId = safeGet(v, 'AssetId') or safeGet(v, 'assetId')
        if assetId ~= nil then
            return normalizeAssetUrl(assetId)
        end

        local contentId = safeGet(v, 'ContentId') or safeGet(v, 'contentId')
        if contentId ~= nil then
            return normalizeAssetUrl(contentId)
        end

        local name = safeGet(v, 'Name')
        if name ~= nil then
            return normalizeAssetUrl(name)
        end

        local ok, s = pcall(tostring, v)
        if ok and type(s) == 'string' and s ~= '' and s ~= 'nil' then
            if isValidAssetUrl(s) then
                if s:find('rbxasset', 1, true) or s:find('http://', 1, true) or s:find('https://', 1, true) then
                    return s
                end
                local num = tonumber(s)
                if num and num > 0 then
                    return 'rbxassetid://' .. tostring(math.floor(num))
                end
            end
        end
        return nil
    end

    if t == 'table' then
        local uri = safeGet(v, 'Uri') or safeGet(v, 'URI') or safeGet(v, 'uri')
        if uri ~= nil then
            return normalizeAssetUrl(uri)
        end

        local value = safeGet(v, 'Value') or safeGet(v, 'value')
        if value ~= nil then
            return normalizeAssetUrl(value)
        end

        local id = safeGet(v, 'Id') or safeGet(v, 'id')
        if id ~= nil then
            return normalizeAssetUrl(id)
        end

        local assetId = safeGet(v, 'AssetId') or safeGet(v, 'assetId')
        if assetId ~= nil then
            return normalizeAssetUrl(assetId)
        end

        local contentId = safeGet(v, 'ContentId') or safeGet(v, 'contentId')
        if contentId ~= nil then
            return normalizeAssetUrl(contentId)
        end

        local name = safeGet(v, 'Name')
        if name ~= nil then
            return normalizeAssetUrl(name)
        end
    end

    local ok, s = pcall(tostring, v)
    if ok and type(s) == 'string' and s ~= '' and s ~= 'nil' then
        if isValidAssetUrl(s) then
            if s:find('rbxasset', 1, true) or s:find('http://', 1, true) or s:find('https://', 1, true) then
                return s
            end
            local num = tonumber(s)
            if num and num > 0 then
                return 'rbxassetid://' .. tostring(math.floor(num))
            end
        end
    end
    return nil
end

local function writeContent(out, name, url)
    if url == nil then
        return
    end
    local raw = tostring(url)
    if raw == '' or raw == 'nil' then
        return
    end
    local normalized = nil
    if raw:find('rbxasset', 1, true) or raw:find('http://', 1, true) or raw:find('https://', 1, true) then
        normalized = raw
    else
        local num = tonumber(raw)
        if num and num > 0 then
            normalized = 'rbxassetid://' .. tostring(math.floor(num))
        else
            normalized = normalizeAssetUrl(url)
        end
    end
    if normalized == nil then
        return
    end
    push(out, '<Content name="' .. xmlEscape(name) .. '">')
    push(out, '<url>' .. xmlEscape(normalized) .. '</url>')
    push(out, '</Content>')
end

local function writeBrickColor(out, name, bc)
    if bc == nil then
        return
    end
    local number = safeGet(bc, 'Number')
    if type(number) == 'number' then
        writeTag(out, 'BrickColor', { name = name }, tostring(math.floor(number)))
        return
    end
    local bcName = safeGet(bc, 'Name')
    if type(bcName) == 'string' then
        writeTag(out, 'BrickColor', { name = name }, xmlEscape(bcName))
        return
    end
end

local function writeVector3(out, name, v)
    if v == nil then
        return
    end
    local x, y, z = v.X, v.Y, v.Z
    if x == nil or y == nil or z == nil then
        return
    end
    push(out, '<Vector3 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'X', nil, tostring(x))
    writeTag(out, 'Y', nil, tostring(y))
    writeTag(out, 'Z', nil, tostring(z))
    push(out, '</Vector3>')
end

local function writeVector2(out, name, v)
    if v == nil then
        return
    end
    local ok, x, y = pcall(function()
        return v.X, v.Y
    end)
    if not ok or x == nil or y == nil then
        return
    end
    push(out, '<Vector2 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'X', nil, tostring(x))
    writeTag(out, 'Y', nil, tostring(y))
    push(out, '</Vector2>')
end

local function writeColor3(out, name, v)
    if v == nil then
        return
    end
    local r, g, b = v.R, v.G, v.B
    if r == nil or g == nil or b == nil then
        return
    end

    local maxc = math.max(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0)
    if maxc > 1.001 then
        if maxc <= 255 then
            r, g, b = r / 255, g / 255, b / 255
        end
    end

    local function clamp01(x)
        x = tonumber(x) or 0
        if x < 0 then return 0 end
        if x > 1 then return 1 end
        return x
    end
    r, g, b = clamp01(r), clamp01(g), clamp01(b)

    push(out, '<Color3 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'R', nil, tostring(r))
    writeTag(out, 'G', nil, tostring(g))
    writeTag(out, 'B', nil, tostring(b))
    push(out, '</Color3>')
end

local function writeCoordinateFrame(out, name, cf, fallbackPos, fallbackOrientation)
    local ok, x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = pcall(function()
        if cf == nil then
            return nil
        end
        if type(cf.GetComponents) == 'function' then
            return cf:GetComponents()
        end
        return cf:components()
    end)

    local function hasFallbackPos()
        return fallbackPos ~= nil and fallbackPos.X ~= nil and fallbackPos.Y ~= nil and fallbackPos.Z ~= nil
    end

    if (not ok) or x == nil then
        if not hasFallbackPos() then
            return
        end
        x, y, z = fallbackPos.X, fallbackPos.Y, fallbackPos.Z
        r00, r01, r02 = 1, 0, 0
        r10, r11, r12 = 0, 1, 0
        r20, r21, r22 = 0, 0, 1
    end

    if hasFallbackPos() and tonumber(x) == 0 and tonumber(y) == 0 and tonumber(z) == 0 then
        if fallbackPos.X ~= 0 or fallbackPos.Y ~= 0 or fallbackPos.Z ~= 0 then
            x, y, z = fallbackPos.X, fallbackPos.Y, fallbackPos.Z
        end
    end

    local function rotValid(a, b, c, d, e, f, g, h, i)
        if a == nil or b == nil or c == nil or d == nil or e == nil or f == nil or g == nil or h == nil or i == nil then
            return false
        end
        local s = math.abs(a) + math.abs(b) + math.abs(c) + math.abs(d) + math.abs(e) + math.abs(f) + math.abs(g) + math.abs(h) + math.abs(i)
        return s > 0.5
    end

    if not rotValid(r00, r01, r02, r10, r11, r12, r20, r21, r22) then
        local o = fallbackOrientation
        if o ~= nil and o.X ~= nil and o.Y ~= nil and o.Z ~= nil then
            local rx = math.rad(o.X)
            local ry = math.rad(o.Y)
            local rz = math.rad(o.Z)
            local cx, sx = math.cos(rx), math.sin(rx)
            local cy, sy = math.cos(ry), math.sin(ry)
            local cz, sz = math.cos(rz), math.sin(rz)

            r00 = cz * cy
            r01 = cz * sy * sx - sz * cx
            r02 = cz * sy * cx + sz * sx

            r10 = sz * cy
            r11 = sz * sy * sx + cz * cx
            r12 = sz * sy * cx - cz * sx

            r20 = -sy
            r21 = cy * sx
            r22 = cy * cx
        else
            r00, r01, r02 = 1, 0, 0
            r10, r11, r12 = 0, 1, 0
            r20, r21, r22 = 0, 0, 1
        end
    end

    push(out, '<CoordinateFrame name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'X', nil, tostring(x))
    writeTag(out, 'Y', nil, tostring(y))
    writeTag(out, 'Z', nil, tostring(z))
    writeTag(out, 'R00', nil, tostring(r00))
    writeTag(out, 'R01', nil, tostring(r01))
    writeTag(out, 'R02', nil, tostring(r02))
    writeTag(out, 'R10', nil, tostring(r10))
    writeTag(out, 'R11', nil, tostring(r11))
    writeTag(out, 'R12', nil, tostring(r12))
    writeTag(out, 'R20', nil, tostring(r20))
    writeTag(out, 'R21', nil, tostring(r21))
    writeTag(out, 'R22', nil, tostring(r22))
    push(out, '</CoordinateFrame>')
end

local function writeToken(out, name, v)
    writeTag(out, 'token', { name = name }, tostring(v))
end

local function writeRef(out, name, referent)
    writeTag(out, 'Ref', { name = name }, referent or 'null')
end

local function writeUDim(out, name, v)
    if v == nil then
        return
    end
    local scale = safeGet(v, 'Scale')
    local offset = safeGet(v, 'Offset')
    if scale == nil or offset == nil then
        return
    end
    push(out, '<UDim name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'S', nil, tostring(scale))
    writeTag(out, 'O', nil, tostring(offset))
    push(out, '</UDim>')
end

local function writeUDim2(out, name, v)
    if v == nil then
        return
    end
    local xs = safeGet(v, 'XScale')
    local xo = safeGet(v, 'XOffset')
    local ys = safeGet(v, 'YScale')
    local yo = safeGet(v, 'YOffset')
    if xs == nil or xo == nil or ys == nil or yo == nil then
        return
    end
    push(out, '<UDim2 name="' .. xmlEscape(name) .. '">')
    push(out, '<XS>' .. tostring(xs) .. '</XS>')
    push(out, '<XO>' .. tostring(xo) .. '</XO>')
    push(out, '<YS>' .. tostring(ys) .. '</YS>')
    push(out, '<YO>' .. tostring(yo) .. '</YO>')
    push(out, '</UDim2>')
end

local function writeNumberSequence(out, name, v)
    if v == nil then
        return
    end
    local keypoints = safeGet(v, 'Keypoints')
    if type(keypoints) ~= 'table' then
        return
    end
    push(out, '<NumberSequence name="' .. xmlEscape(name) .. '">')
    for _, kp in ipairs(keypoints) do
        local t = safeGet(kp, 'Time')
        local val = safeGet(kp, 'Value')
        local e = safeGet(kp, 'Envelope')
        if t ~= nil and val ~= nil then
            push(out, '<Keypoint time="' .. tostring(t) .. '" value="' .. tostring(val) .. '" envelope="' .. tostring(e or 0) .. '"/>')
        end
    end
    push(out, '</NumberSequence>')
end

local function writeColorSequence(out, name, v)
    if v == nil then
        return
    end
    local keypoints = safeGet(v, 'Keypoints')
    if type(keypoints) ~= 'table' then
        return
    end
    push(out, '<ColorSequence name="' .. xmlEscape(name) .. '">')
    for _, kp in ipairs(keypoints) do
        local t = safeGet(kp, 'Time')
        local val = safeGet(kp, 'Value')
        if t ~= nil and val ~= nil then
            local r, g, b = safeGet(val, 'R'), safeGet(val, 'G'), safeGet(val, 'B')
            if r and g and b then
                push(out, string.format('<Keypoint time="%s" r="%s" g="%s" b="%s"/>', tostring(t), tostring(r), tostring(g), tostring(b)))
            end
        end
    end
    push(out, '</ColorSequence>')
end

local function writeNumberRange(out, name, v)
    if v == nil then
        return
    end
    local min = safeGet(v, 'Min')
    local max = safeGet(v, 'Max')
    if min == nil or max == nil then
        return
    end
    push(out, '<NumberRange name="' .. xmlEscape(name) .. '">')
    push(out, '<Min>' .. tostring(min) .. '</Min>')
    push(out, '<Max>' .. tostring(max) .. '</Max>')
    push(out, '</NumberRange>')
end

local function writeFaces(out, name, v)
    if v == nil then
        return
    end
    local fv = safeGet(v, 'Value')
    if type(fv) == 'number' then
        writeToken(out, name, fv)
    end
end

local function writeRect(out, name, v)
    if v == nil then
        return
    end
    local min = safeGet(v, 'Min')
    local max = safeGet(v, 'Max')
    if min == nil or max == nil then
        return
    end
    local minX, minY = safeGet(min, 'X'), safeGet(min, 'Y')
    local maxX, maxY = safeGet(max, 'X'), safeGet(max, 'Y')
    if minX == nil or minY == nil or maxX == nil or maxY == nil then
        return
    end
    push(out, '<Rect name="' .. xmlEscape(name) .. '">')
    push(out, '<Min><X>' .. tostring(minX) .. '</X><Y>' .. tostring(minY) .. '</Y></Min>')
    push(out, '<Max><X>' .. tostring(maxX) .. '</X><Y>' .. tostring(maxY) .. '</Y></Max>')
    push(out, '</Rect>')
end

local function writeRegion3(out, name, v)
    if v == nil then
        return
    end
    local minV = safeGet(v, 'CFrame')
    local maxV = safeGet(v, 'Size')
    if minV == nil or maxV == nil then
        return
    end
    local minPos = safeGet(minV, 'Position')
    if minPos == nil then
        return
    end
    local mx, my, mz = safeGet(minPos, 'X'), safeGet(minPos, 'Y'), safeGet(minPos, 'Z')
    local sx, sy, sz = safeGet(maxV, 'X'), safeGet(maxV, 'Y'), safeGet(maxV, 'Z')
    if mx == nil or my == nil or mz == nil or sx == nil or sy == nil or sz == nil then
        return
    end
    push(out, '<Region3 name="' .. xmlEscape(name) .. '">')
    push(out, '<CFrame><X>' .. tostring(mx) .. '</X><Y>' .. tostring(my) .. '</Y><Z>' .. tostring(mz) .. '</Z></CFrame>')
    push(out, '<Size><X>' .. tostring(sx) .. '</X><Y>' .. tostring(sy) .. '</Y><Z>' .. tostring(sz) .. '</Z></Size>')
    push(out, '</Region3>')
end

local function writeTweenInfo(out, name, v)
    if v == nil then
        return
    end
    local time = safeGet(v, 'Time')
    local style = safeGet(v, 'EasingStyle')
    local dir = safeGet(v, 'EasingDirection')
    local rCount = safeGet(v, 'RepeatCount')
    local reverses = safeGet(v, 'Reverses')
    local delayTime = safeGet(v, 'DelayTime')

    local styleVal = (type(style) == 'table') and safeGet(style, 'Value') or nil
    local dirVal = (type(dir) == 'table') and safeGet(dir, 'Value') or nil

    push(out, '<TweenInfo name="' .. xmlEscape(name) .. '">')
    if time ~= nil then writeTag(out, 'Time', nil, tostring(time)) end
    if styleVal ~= nil then writeToken(out, 'EasingStyle', styleVal) end
    if dirVal ~= nil then writeToken(out, 'EasingDirection', dirVal) end
    if rCount ~= nil then writeTag(out, 'RepeatCount', nil, tostring(rCount)) end
    if reverses ~= nil then writeBool(out, 'Reverses', reverses) end
    if delayTime ~= nil then writeTag(out, 'DelayTime', nil, tostring(delayTime)) end
    push(out, '</TweenInfo>')
end

local function writePhysicalProperties(out, name, v)
    if v == nil then
        return
    end
    local density = safeGet(v, 'Density')
    local friction = safeGet(v, 'Friction')
    local elasticity = safeGet(v, 'Elasticity')
    local fricWeight = safeGet(v, 'FrictionWeight')
    local elasWeight = safeGet(v, 'ElasticityWeight')

    push(out, '<PhysicalProperties name="' .. xmlEscape(name) .. '">')
    if density ~= nil then writeTag(out, 'Density', nil, tostring(density)) end
    if friction ~= nil then writeTag(out, 'Friction', nil, tostring(friction)) end
    if elasticity ~= nil then writeTag(out, 'Elasticity', nil, tostring(elasticity)) end
    if fricWeight ~= nil then writeTag(out, 'FrictionWeight', nil, tostring(fricWeight)) end
    if elasWeight ~= nil then writeTag(out, 'ElasticityWeight', nil, tostring(elasWeight)) end
    push(out, '</PhysicalProperties>')
end

local function writeAny(out, name, v, state)
    if v == nil then
        return
    end

    local tv = type(v)
    if tv == 'boolean' then
        writeBool(out, name, v)
        return
    end
    if tv == 'number' then
        writeFloat(out, name, v)
        return
    end
    if tv == 'string' then
        writeString(out, name, v)
        return
    end

    local enumValue = safeGet(v, 'Value')
    if type(enumValue) == 'number' then
        writeToken(out, name, enumValue)
        return
    end

    local className = safeGet(v, 'ClassName')
    if state and state.referentOf and type(className) == 'string' then
        local ref = state.referentOf[v]
        writeRef(out, name, ref)
        return
    end

    local okCf = pcall(function()
        if type(v.GetComponents) == 'function' then
            return v:GetComponents()
        end
        return v:components()
    end)
    if okCf then
        writeCoordinateFrame(out, name, v)
        return
    end

    local x = safeGet(v, 'X')
    local y = safeGet(v, 'Y')
    local z = safeGet(v, 'Z')
    if type(x) == 'number' and type(y) == 'number' and type(z) == 'number' then
        local w = safeGet(v, 'W')
        if type(w) == 'number' then
            writeCoordinateFrame(out, name, v)
        else
            writeVector3(out, name, v)
        end
        return
    end

    local r = safeGet(v, 'R')
    local g = safeGet(v, 'G')
    local b = safeGet(v, 'B')
    if type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
        writeColor3(out, name, v)
        return
    end

    local scale = safeGet(v, 'Scale')
    local offset = safeGet(v, 'Offset')
    if type(scale) == 'number' and type(offset) == 'number' then
        local isUDim2 = safeGet(v, 'XScale') or safeGet(v, 'YScale')
        if isUDim2 then
            writeUDim2(out, name, v)
        else
            writeUDim(out, name, v)
        end
        return
    end

    local keypoints = safeGet(v, 'Keypoints')
    if type(keypoints) == 'table' and #keypoints > 0 then
        local firstKP = keypoints[1]
        local kpVal = safeGet(firstKP, 'Value')
        if type(kpVal) == 'number' then
            writeNumberSequence(out, name, v)
        elseif kpVal ~= nil then
            writeColorSequence(out, name, v)
        end
        return
    end

    local minVal = safeGet(v, 'Min')
    local maxVal = safeGet(v, 'Max')
    if minVal ~= nil and maxVal ~= nil and type(minVal) == 'number' and type(maxVal) == 'number' then
        writeNumberRange(out, name, v)
        return
    end

    local density = safeGet(v, 'Density')
    if type(density) == 'number' then
        writePhysicalProperties(out, name, v)
        return
    end

    local time = safeGet(v, 'Time')
    local easingStyle = safeGet(v, 'EasingStyle')
    if type(time) == 'number' and easingStyle ~= nil then
        writeTweenInfo(out, name, v)
        return
    end

    local face = safeGet(v, 'Value')
    if type(face) == 'number' and (name == 'Face' or name == 'NormalId' or name == 'Axis') then
        writeToken(out, name, face)
        return
    end

    local rectMin = safeGet(v, 'Min')
    local rectMax = safeGet(v, 'Max')
    if rectMin ~= nil and rectMax ~= nil then
        local rmX = safeGet(rectMin, 'X')
        local rmY = safeGet(rectMin, 'Y')
        if type(rmX) == 'number' and type(rmY) == 'number' then
            writeRect(out, name, v)
            return
        end
    end

    writeString(out, name, tostring(v))
end

local function writeContentProps(out, inst, className)
    local list = CONTENT_PROPS_BY_CLASSNAME[className]
    if not list then
        return
    end
    for _, prop in ipairs(list) do
        writeContent(out, prop, safeGet(inst, prop))
    end
end

local function writeBasePartProperties(out, inst)
    local posFallback = safeGet(inst, 'Position')
    writeCoordinateFrame(out, 'CFrame', safeGet(inst, 'CFrame'), posFallback, safeGet(inst, 'Orientation'))
    writeVector3(out, 'Size', safeGet(inst, 'Size'))

    writeBool(out, 'Anchored', safeGet(inst, 'Anchored'))
    writeBool(out, 'CanCollide', safeGet(inst, 'CanCollide'))
    writeBool(out, 'CanQuery', safeGet(inst, 'CanQuery'))
    writeBool(out, 'CanTouch', safeGet(inst, 'CanTouch'))
    writeBool(out, 'Massless', safeGet(inst, 'Massless'))
    writeBool(out, 'CastShadow', safeGet(inst, 'CastShadow'))
    writeBool(out, 'Locked', safeGet(inst, 'Locked'))

    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeFloat(out, 'Reflectance', safeGet(inst, 'Reflectance'))

    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeBrickColor(out, 'BrickColor', safeGet(inst, 'BrickColor'))

    local cgid = safeGet(inst, 'CollisionGroupId')
    if type(cgid) == 'number' then
        writeInt(out, 'CollisionGroupId', math.floor(cgid))
    end

    local mat = safeGet(inst, 'Material')
    local matValue = (type(mat) == 'table') and safeGet(mat, 'Value') or nil
    if type(matValue) == 'number' then
        writeToken(out, 'Material', matValue)
    end

    writeVector3(out, 'Velocity', safeGet(inst, 'Velocity'))
    writeVector3(out, 'AssemblyLinearVelocity', safeGet(inst, 'AssemblyLinearVelocity'))

    writePhysicalProperties(out, 'CustomPhysicalProperties', safeGet(inst, 'CustomPhysicalProperties'))
end

local function writeGuiObjectProperties(out, inst)
    writeBool(out, 'Active', safeGet(inst, 'Active'))
    writeBool(out, 'ClipsDescendants', safeGet(inst, 'ClipsDescendants'))
    writeBool(out, 'Visible', safeGet(inst, 'Visible'))

    writeUDim2(out, 'Position', safeGet(inst, 'Position'))
    writeUDim2(out, 'Size', safeGet(inst, 'Size'))
    writeVector2(out, 'AnchorPoint', safeGet(inst, 'AnchorPoint'))
    writeVector2(out, 'AbsoluteSize', safeGet(inst, 'AbsoluteSize'))
    writeVector2(out, 'AbsolutePosition', safeGet(inst, 'AbsolutePosition'))

    writeColor3(out, 'BackgroundColor3', safeGet(inst, 'BackgroundColor3'))
    writeFloat(out, 'BackgroundTransparency', safeGet(inst, 'BackgroundTransparency'))
    writeColor3(out, 'BorderColor3', safeGet(inst, 'BorderColor3'))
    writeInt(out, 'BorderSizePixel', safeGet(inst, 'BorderSizePixel'))
    writeInt(out, 'ZIndex', safeGet(inst, 'ZIndex'))
    writeInt(out, 'LayoutOrder', safeGet(inst, 'LayoutOrder'))
    writeFloat(out, 'Rotation', safeGet(inst, 'Rotation'))
end

CLASS_HANDLERS.MeshPart = function(out, inst, _state)
    writeContentProps(out, inst, 'MeshPart')

    local function tryWriteRawContent(propName)
        local raw = safeGet(inst, propName)
        if raw == nil then
            return
        end
        local s = tostring(raw)
        if s == '' or s == 'nil' or s == 'nil' then
            return
        end
        if s:find('rbxasset', 1, true) or s:find('http://', 1, true) or s:find('https://', 1, true) then
            writeContent(out, propName, s)
            return
        end
        local num = tonumber(s)
        if num and num > 0 then
            writeContent(out, propName, 'rbxassetid://' .. tostring(math.floor(num)))
            return
        end
    end

    tryWriteRawContent('MeshId')
    tryWriteRawContent('TextureID')
    tryWriteRawContent('TextureId')
end

CLASS_HANDLERS.SpecialMesh = function(out, inst, _state)
    writeContentProps(out, inst, 'SpecialMesh')
    writeVector3(out, 'Scale', safeGet(inst, 'Scale'))
    writeVector3(out, 'Offset', safeGet(inst, 'Offset'))
    local mt = safeGet(inst, 'MeshType')
    local mtVal = (type(mt) == 'table') and safeGet(mt, 'Value') or nil
    if type(mtVal) == 'number' then
        writeToken(out, 'MeshType', mtVal)
    end
    local rawMesh = safeGet(inst, 'MeshId')
    if rawMesh ~= nil then
        local s = tostring(rawMesh)
        if s ~= '' and s ~= 'nil' then
            if s:find('rbxasset', 1, true) or s:find('http://', 1, true) then
                writeContent(out, 'MeshId', s)
            else
                local num = tonumber(s)
                if num and num > 0 then
                    writeContent(out, 'MeshId', 'rbxassetid://' .. tostring(math.floor(num)))
                end
            end
        end
    end
    local rawTex = safeGet(inst, 'TextureId')
    if rawTex ~= nil then
        local s = tostring(rawTex)
        if s ~= '' and s ~= 'nil' then
            if s:find('rbxasset', 1, true) or s:find('http://', 1, true) then
                writeContent(out, 'TextureId', s)
            else
                local num = tonumber(s)
                if num and num > 0 then
                    writeContent(out, 'TextureId', 'rbxassetid://' .. tostring(math.floor(num)))
                end
            end
        end
    end
end

CLASS_HANDLERS.BlockMesh = function(out, inst, _state)
    writeContentProps(out, inst, 'BlockMesh')
    writeVector3(out, 'Scale', safeGet(inst, 'Scale'))
    writeVector3(out, 'Offset', safeGet(inst, 'Offset'))
end

CLASS_HANDLERS.CylinderMesh = function(out, inst, _state)
    writeContentProps(out, inst, 'CylinderMesh')
    writeVector3(out, 'Scale', safeGet(inst, 'Scale'))
    writeVector3(out, 'Offset', safeGet(inst, 'Offset'))
end

CLASS_HANDLERS.CharacterMesh = function(out, inst, _state)
    writeContentProps(out, inst, 'CharacterMesh')
    local bp = safeGet(inst, 'BodyPart')
    local bpValue = (type(bp) == 'table') and safeGet(bp, 'Value') or nil
    if type(bpValue) == 'number' then
        writeToken(out, 'BodyPart', bpValue)
    end
end

CLASS_HANDLERS.SurfaceAppearance = function(out, inst, _state)
    writeContentProps(out, inst, 'SurfaceAppearance')
end

CLASS_HANDLERS.Decal = function(out, inst, _state)
    writeContentProps(out, inst, 'Decal')
    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeColor3(out, 'Color3', safeGet(inst, 'Color3'))
    local face = safeGet(inst, 'Face')
    local faceValue = (type(face) == 'table') and safeGet(face, 'Value') or nil
    if type(faceValue) == 'number' then
        writeToken(out, 'Face', faceValue)
    end
end

CLASS_HANDLERS.Texture = function(out, inst, _state)
    writeContentProps(out, inst, 'Texture')
    writeFloat(out, 'StudsPerTileU', safeGet(inst, 'StudsPerTileU'))
    writeFloat(out, 'StudsPerTileV', safeGet(inst, 'StudsPerTileV'))
    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeColor3(out, 'Color3', safeGet(inst, 'Color3'))
    local face = safeGet(inst, 'Face')
    local faceValue = (type(face) == 'table') and safeGet(face, 'Value') or nil
    if type(faceValue) == 'number' then
        writeToken(out, 'Face', faceValue)
    end
end

CLASS_HANDLERS.ParticleEmitter = function(out, inst, _state)
    writeContentProps(out, inst, 'ParticleEmitter')
    writeNumberSequence(out, 'Color', safeGet(inst, 'Color'))
    writeNumberSequence(out, 'Size', safeGet(inst, 'Size'))
    writeNumberSequence(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeNumberRange(out, 'Lifetime', safeGet(inst, 'Lifetime'))
    writeNumberRange(out, 'Speed', safeGet(inst, 'Speed'))
    writeNumberRange(out, 'Rotation', safeGet(inst, 'Rotation'))
    writeNumberRange(out, 'RotSpeed', safeGet(inst, 'RotSpeed'))
    writeFloat(out, 'Rate', safeGet(inst, 'Rate'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Drag', safeGet(inst, 'Drag'))
    writeFloat(out, 'LightEmission', safeGet(inst, 'LightEmission'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeBool(out, 'LockedToPart', safeGet(inst, 'LockedToPart'))
    writeVector3(out, 'SpreadAngle', safeGet(inst, 'SpreadAngle'))
    writeFloat(out, 'TimeScale', safeGet(inst, 'TimeScale'))
    writeFloat(out, 'VelocityInheritance', safeGet(inst, 'VelocityInheritance'))
    writeFloat(out, 'ZOffset', safeGet(inst, 'ZOffset'))
    local ed = safeGet(inst, 'EmissionDirection')
    local edVal = (type(ed) == 'table') and safeGet(ed, 'Value') or nil
    if type(edVal) == 'number' then
        writeToken(out, 'EmissionDirection', edVal)
    end
end

CLASS_HANDLERS.Fire = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeColor3(out, 'SecondaryColor', safeGet(inst, 'SecondaryColor'))
    writeFloat(out, 'Heat', safeGet(inst, 'Heat'))
    writeFloat(out, 'LightEmission', safeGet(inst, 'LightEmission'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeFloat(out, 'Size', safeGet(inst, 'Size'))
    writeFloat(out, 'TimeScale', safeGet(inst, 'TimeScale'))
end

CLASS_HANDLERS.Smoke = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeFloat(out, 'LightEmission', safeGet(inst, 'LightEmission'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeFloat(out, 'Opacity', safeGet(inst, 'Opacity'))
    writeFloat(out, 'RiseVelocity', safeGet(inst, 'RiseVelocity'))
    writeFloat(out, 'Size', safeGet(inst, 'Size'))
    writeFloat(out, 'TimeScale', safeGet(inst, 'TimeScale'))
end

CLASS_HANDLERS.Explosion = function(out, inst, _state)
    writeFloat(out, 'BlastPressure', safeGet(inst, 'BlastPressure'))
    writeFloat(out, 'BlastRadius', safeGet(inst, 'BlastRadius'))
    writeFloat(out, 'DestroyJointRadiusPercent', safeGet(inst, 'DestroyJointRadiusPercent'))
    writeVector3(out, 'Position', safeGet(inst, 'Position'))
    writeBool(out, 'Visible', safeGet(inst, 'Visible'))
    local et = safeGet(inst, 'ExplosionType')
    local etVal = (type(et) == 'table') and safeGet(et, 'Value') or nil
    if type(etVal) == 'number' then
        writeToken(out, 'ExplosionType', etVal)
    end
end

CLASS_HANDLERS.Sound = function(out, inst, _state)
    writeContentProps(out, inst, 'Sound')
    writeBool(out, 'Looped', safeGet(inst, 'Looped'))
    writeBool(out, 'Playing', safeGet(inst, 'Playing'))
    writeBool(out, 'PlayOnRemove', safeGet(inst, 'PlayOnRemove'))
    writeFloat(out, 'PlaybackSpeed', safeGet(inst, 'PlaybackSpeed'))
    writeFloat(out, 'TimePosition', safeGet(inst, 'TimePosition'))
    writeFloat(out, 'Volume', safeGet(inst, 'Volume'))
    writeFloat(out, 'RollOffMaxDistance', safeGet(inst, 'RollOffMaxDistance'))
    writeFloat(out, 'RollOffMinDistance', safeGet(inst, 'RollOffMinDistance'))
    local rom = safeGet(inst, 'RollOffMode')
    local romVal = (type(rom) == 'table') and safeGet(rom, 'Value') or nil
    if type(romVal) == 'number' then
        writeToken(out, 'RollOffMode', romVal)
    end
end

CLASS_HANDLERS.BloomEffect = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Intensity', safeGet(inst, 'Intensity'))
    writeFloat(out, 'Size', safeGet(inst, 'Size'))
    writeFloat(out, 'Threshold', safeGet(inst, 'Threshold'))
end

CLASS_HANDLERS.BlurEffect = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Size', safeGet(inst, 'Size'))
end

CLASS_HANDLERS.ColorCorrectionEffect = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Brightness', safeGet(inst, 'Brightness'))
    writeFloat(out, 'Contrast', safeGet(inst, 'Contrast'))
    writeFloat(out, 'Saturation', safeGet(inst, 'Saturation'))
    writeColor3(out, 'TintColor', safeGet(inst, 'TintColor'))
end

CLASS_HANDLERS.ColorGradingEffect = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local tp = safeGet(inst, 'TonemapperPreset')
    local tpVal = (type(tp) == 'table') and safeGet(tp, 'Value') or nil
    if type(tpVal) == 'number' then
        writeToken(out, 'TonemapperPreset', tpVal)
    end
end

CLASS_HANDLERS.DepthOfFieldEffect = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'FarIntensity', safeGet(inst, 'FarIntensity'))
    writeFloat(out, 'FocusDistance', safeGet(inst, 'FocusDistance'))
    writeFloat(out, 'InFocusRadius', safeGet(inst, 'InFocusRadius'))
    writeFloat(out, 'NearIntensity', safeGet(inst, 'NearIntensity'))
end

CLASS_HANDLERS.SunRaysEffect = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Intensity', safeGet(inst, 'Intensity'))
    writeFloat(out, 'Spread', safeGet(inst, 'Spread'))
end

CLASS_HANDLERS.Atmospheric = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Density', safeGet(inst, 'Density'))
    writeFloat(out, 'Haze', safeGet(inst, 'Haze'))
    writeFloat(out, 'Glare', safeGet(inst, 'Glare'))
    writeFloat(out, 'Decay', safeGet(inst, 'Decay'))
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
end

CLASS_HANDLERS.Shirt = function(out, inst, _state)
    writeContentProps(out, inst, 'Shirt')
end

CLASS_HANDLERS.Pants = function(out, inst, _state)
    writeContentProps(out, inst, 'Pants')
end

CLASS_HANDLERS.ShirtGraphic = function(out, inst, _state)
    writeContentProps(out, inst, 'ShirtGraphic')
end

CLASS_HANDLERS.ImageLabel = function(out, inst, _state)
    writeContentProps(out, inst, 'ImageLabel')
    writeColor3(out, 'ImageColor3', safeGet(inst, 'ImageColor3'))
    writeFloat(out, 'ImageTransparency', safeGet(inst, 'ImageTransparency'))
    local st = safeGet(inst, 'ScaleType')
    local stVal = (type(st) == 'table') and safeGet(st, 'Value') or nil
    if type(stVal) == 'number' then
        writeToken(out, 'ScaleType', stVal)
    end
end

CLASS_HANDLERS.ImageButton = function(out, inst, _state)
    writeContentProps(out, inst, 'ImageButton')
    writeColor3(out, 'ImageColor3', safeGet(inst, 'ImageColor3'))
    writeFloat(out, 'ImageTransparency', safeGet(inst, 'ImageTransparency'))
    writeBool(out, 'AutoButtonColor', safeGet(inst, 'AutoButtonColor'))
    writeBool(out, 'Modal', safeGet(inst, 'Modal'))
    local st = safeGet(inst, 'ScaleType')
    local stVal = (type(st) == 'table') and safeGet(st, 'Value') or nil
    if type(stVal) == 'number' then
        writeToken(out, 'ScaleType', stVal)
    end
end

CLASS_HANDLERS.TextLabel = function(out, inst, _state)
    writeString(out, 'Text', safeGet(inst, 'Text'))
    writeColor3(out, 'TextColor3', safeGet(inst, 'TextColor3'))
    writeFloat(out, 'TextTransparency', safeGet(inst, 'TextTransparency'))
    writeBool(out, 'TextScaled', safeGet(inst, 'TextScaled'))
    writeInt(out, 'TextSize', safeGet(inst, 'TextSize'))
    writeBool(out, 'TextWrapped', safeGet(inst, 'TextWrapped'))
    writeBool(out, 'RichText', safeGet(inst, 'RichText'))
    local txa = safeGet(inst, 'TextXAlignment')
    local txaVal = (type(txa) == 'table') and safeGet(txa, 'Value') or nil
    if type(txaVal) == 'number' then
        writeToken(out, 'TextXAlignment', txaVal)
    end
    local tya = safeGet(inst, 'TextYAlignment')
    local tyaVal = (type(tya) == 'table') and safeGet(tya, 'Value') or nil
    if type(tyaVal) == 'number' then
        writeToken(out, 'TextYAlignment', tyaVal)
    end
    local f = safeGet(inst, 'Font')
    local fVal = (type(f) == 'table') and safeGet(f, 'Value') or nil
    if type(fVal) == 'number' then
        writeToken(out, 'Font', fVal)
    end
end

CLASS_HANDLERS.TextButton = function(out, inst, _state)
    writeString(out, 'Text', safeGet(inst, 'Text'))
    writeColor3(out, 'TextColor3', safeGet(inst, 'TextColor3'))
    writeFloat(out, 'TextTransparency', safeGet(inst, 'TextTransparency'))
    writeBool(out, 'TextScaled', safeGet(inst, 'TextScaled'))
    writeInt(out, 'TextSize', safeGet(inst, 'TextSize'))
    writeBool(out, 'TextWrapped', safeGet(inst, 'TextWrapped'))
    writeBool(out, 'RichText', safeGet(inst, 'RichText'))
    writeBool(out, 'AutoButtonColor', safeGet(inst, 'AutoButtonColor'))
    writeBool(out, 'Modal', safeGet(inst, 'Modal'))
    local txa = safeGet(inst, 'TextXAlignment')
    local txaVal = (type(txa) == 'table') and safeGet(txa, 'Value') or nil
    if type(txaVal) == 'number' then
        writeToken(out, 'TextXAlignment', txaVal)
    end
    local tya = safeGet(inst, 'TextYAlignment')
    local tyaVal = (type(tya) == 'table') and safeGet(tya, 'Value') or nil
    if type(tyaVal) == 'number' then
        writeToken(out, 'TextYAlignment', tyaVal)
    end
    local f = safeGet(inst, 'Font')
    local fVal = (type(f) == 'table') and safeGet(f, 'Value') or nil
    if type(fVal) == 'number' then
        writeToken(out, 'Font', fVal)
    end
end

CLASS_HANDLERS.TextBox = function(out, inst, _state)
    writeString(out, 'Text', safeGet(inst, 'Text'))
    writeColor3(out, 'TextColor3', safeGet(inst, 'TextColor3'))
    writeFloat(out, 'TextTransparency', safeGet(inst, 'TextTransparency'))
    writeBool(out, 'TextScaled', safeGet(inst, 'TextScaled'))
    writeInt(out, 'TextSize', safeGet(inst, 'TextSize'))
    writeBool(out, 'TextWrapped', safeGet(inst, 'TextWrapped'))
    writeBool(out, 'RichText', safeGet(inst, 'RichText'))
    writeBool(out, 'ClearTextOnFocus', safeGet(inst, 'ClearTextOnFocus'))
    writeBool(out, 'MultiLine', safeGet(inst, 'MultiLine'))
    writeBool(out, 'TextEditable', safeGet(inst, 'TextEditable'))
    writeColor3(out, 'PlaceholderColor3', safeGet(inst, 'PlaceholderColor3'))
    writeString(out, 'PlaceholderText', safeGet(inst, 'PlaceholderText'))
    local f = safeGet(inst, 'Font')
    local fVal = (type(f) == 'table') and safeGet(f, 'Value') or nil
    if type(fVal) == 'number' then
        writeToken(out, 'Font', fVal)
    end
end

CLASS_HANDLERS.Frame = function(out, inst, _state)
    local style = safeGet(inst, 'Style')
    local styleVal = (type(style) == 'table') and safeGet(style, 'Value') or nil
    if type(styleVal) == 'number' then
        writeToken(out, 'Style', styleVal)
    end
end

CLASS_HANDLERS.ScrollingFrame = function(out, inst, _state)
    writeVector2(out, 'CanvasSize', safeGet(inst, 'CanvasSize'))
    writeVector2(out, 'CanvasPosition', safeGet(inst, 'CanvasPosition'))
    writeInt(out, 'ScrollBarThickness', safeGet(inst, 'ScrollBarThickness'))
    writeColor3(out, 'ScrollBarImageColor3', safeGet(inst, 'ScrollBarImageColor3'))
    writeFloat(out, 'ScrollBarImageTransparency', safeGet(inst, 'ScrollBarImageTransparency'))
    writeBool(out, 'ScrollingEnabled', safeGet(inst, 'ScrollingEnabled'))
    local sd = safeGet(inst, 'ScrollingDirection')
    local sdVal = (type(sd) == 'table') and safeGet(sd, 'Value') or nil
    if type(sdVal) == 'number' then
        writeToken(out, 'ScrollingDirection', sdVal)
    end
end

CLASS_HANDLERS.UICorner = function(out, inst, _state)
    writeUDim(out, 'CornerRadius', safeGet(inst, 'CornerRadius'))
end

CLASS_HANDLERS.UIStroke = function(out, inst, _state)
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeFloat(out, 'Thickness', safeGet(inst, 'Thickness'))
    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local asm = safeGet(inst, 'ApplyStrokeMode')
    local asmVal = (type(asm) == 'table') and safeGet(asm, 'Value') or nil
    if type(asmVal) == 'number' then
        writeToken(out, 'ApplyStrokeMode', asmVal)
    end
    local jl = safeGet(inst, 'LineJoinMode')
    local jlVal = (type(jl) == 'table') and safeGet(jl, 'Value') or nil
    if type(jlVal) == 'number' then
        writeToken(out, 'LineJoinMode', jlVal)
    end
end

CLASS_HANDLERS.UIGradient = function(out, inst, _state)
    writeColorSequence(out, 'Color', safeGet(inst, 'Color'))
    writeNumberSequence(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeVector2(out, 'Offset', safeGet(inst, 'Offset'))
    writeFloat(out, 'Rotation', safeGet(inst, 'Rotation'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.UIPadding = function(out, inst, _state)
    writeUDim(out, 'PaddingBottom', safeGet(inst, 'PaddingBottom'))
    writeUDim(out, 'PaddingLeft', safeGet(inst, 'PaddingLeft'))
    writeUDim(out, 'PaddingRight', safeGet(inst, 'PaddingRight'))
    writeUDim(out, 'PaddingTop', safeGet(inst, 'PaddingTop'))
end

CLASS_HANDLERS.UIListLayout = function(out, inst, _state)
    local fd = safeGet(inst, 'FillDirection')
    local fdVal = (type(fd) == 'table') and safeGet(fd, 'Value') or nil
    if type(fdVal) == 'number' then
        writeToken(out, 'FillDirection', fdVal)
    end
    local ha = safeGet(inst, 'HorizontalAlignment')
    local haVal = (type(ha) == 'table') and safeGet(ha, 'Value') or nil
    if type(haVal) == 'number' then
        writeToken(out, 'HorizontalAlignment', haVal)
    end
    local va = safeGet(inst, 'VerticalAlignment')
    local vaVal = (type(va) == 'table') and safeGet(va, 'Value') or nil
    if type(vaVal) == 'number' then
        writeToken(out, 'VerticalAlignment', vaVal)
    end
    local so = safeGet(inst, 'SortOrder')
    local soVal = (type(so) == 'table') and safeGet(so, 'Value') or nil
    if type(soVal) == 'number' then
        writeToken(out, 'SortOrder', soVal)
    end
    writeUDim(out, 'Padding', safeGet(inst, 'Padding'))
    writeBool(out, 'Wraps', safeGet(inst, 'Wraps'))
end

CLASS_HANDLERS.UIGridLayout = function(out, inst, _state)
    writeUDim2(out, 'CellPadding', safeGet(inst, 'CellPadding'))
    writeUDim2(out, 'CellSize', safeGet(inst, 'CellSize'))
    local fd = safeGet(inst, 'FillDirection')
    local fdVal = (type(fd) == 'table') and safeGet(fd, 'Value') or nil
    if type(fdVal) == 'number' then
        writeToken(out, 'FillDirection', fdVal)
    end
    local ha = safeGet(inst, 'HorizontalAlignment')
    local haVal = (type(ha) == 'table') and safeGet(ha, 'Value') or nil
    if type(haVal) == 'number' then
        writeToken(out, 'HorizontalAlignment', haVal)
    end
    local va = safeGet(inst, 'VerticalAlignment')
    local vaVal = (type(va) == 'table') and safeGet(va, 'Value') or nil
    if type(vaVal) == 'number' then
        writeToken(out, 'VerticalAlignment', vaVal)
    end
    local so = safeGet(inst, 'SortOrder')
    local soVal = (type(so) == 'table') and safeGet(so, 'Value') or nil
    if type(soVal) == 'number' then
        writeToken(out, 'SortOrder', soVal)
    end
end

CLASS_HANDLERS.UIAspectRatioConstraint = function(out, inst, _state)
    writeFloat(out, 'AspectRatio', safeGet(inst, 'AspectRatio'))
    local at = safeGet(inst, 'AspectType')
    local atVal = (type(at) == 'table') and safeGet(at, 'Value') or nil
    if type(atVal) == 'number' then
        writeToken(out, 'AspectType', atVal)
    end
    local da = safeGet(inst, 'DominantAxis')
    local daVal = (type(da) == 'table') and safeGet(da, 'Value') or nil
    if type(daVal) == 'number' then
        writeToken(out, 'DominantAxis', daVal)
    end
end

CLASS_HANDLERS.UISizeConstraint = function(out, inst, _state)
    writeVector2(out, 'MaxSize', safeGet(inst, 'MaxSize'))
    writeVector2(out, 'MinSize', safeGet(inst, 'MinSize'))
end

CLASS_HANDLERS.UIScale = function(out, inst, _state)
    writeFloat(out, 'Scale', safeGet(inst, 'Scale'))
end

CLASS_HANDLERS.Motor6D = function(out, inst, state)
    writeCoordinateFrame(out, 'C0', safeGet(inst, 'C0'))
    writeCoordinateFrame(out, 'C1', safeGet(inst, 'C1'))
    writeCoordinateFrame(out, 'Transform', safeGet(inst, 'Transform'))

    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end

    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.Weld = function(out, inst, state)
    writeCoordinateFrame(out, 'C0', safeGet(inst, 'C0'))
    writeCoordinateFrame(out, 'C1', safeGet(inst, 'C1'))

    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end

    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.WeldConstraint = function(out, inst, state)
    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.ManualWeld = function(out, inst, state)
    writeCoordinateFrame(out, 'C0', safeGet(inst, 'C0'))
    writeCoordinateFrame(out, 'C1', safeGet(inst, 'C1'))

    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end
end

CLASS_HANDLERS.Attachment = function(out, inst, _state)
    writeCoordinateFrame(out, 'CFrame', safeGet(inst, 'CFrame'))
    writeVector3(out, 'Axis', safeGet(inst, 'Axis'))
    writeVector3(out, 'SecondaryAxis', safeGet(inst, 'SecondaryAxis'))
    writeBool(out, 'Visible', safeGet(inst, 'Visible'))
end

CLASS_HANDLERS.Accessory = function(out, inst, _state)
    writeCoordinateFrame(out, 'AttachmentPoint', safeGet(inst, 'AttachmentPoint'))
    local at = safeGet(inst, 'AccessoryType')
    local atValue = (type(at) == 'table') and safeGet(at, 'Value') or nil
    if type(atValue) == 'number' then
        writeToken(out, 'AccessoryType', atValue)
    end
end

CLASS_HANDLERS.Hat = function(out, inst, _state)
    writeCoordinateFrame(out, 'AttachmentPoint', safeGet(inst, 'AttachmentPoint'))
    writeVector3(out, 'AttachmentForward', safeGet(inst, 'AttachmentForward'))
    writeVector3(out, 'AttachmentPos', safeGet(inst, 'AttachmentPos'))
    writeVector3(out, 'AttachmentRight', safeGet(inst, 'AttachmentRight'))
    writeVector3(out, 'AttachmentUp', safeGet(inst, 'AttachmentUp'))
end

CLASS_HANDLERS.BodyColors = function(out, inst, _state)
    writeBrickColor(out, 'HeadColor', safeGet(inst, 'HeadColor'))
    writeBrickColor(out, 'LeftArmColor', safeGet(inst, 'LeftArmColor'))
    writeBrickColor(out, 'RightArmColor', safeGet(inst, 'RightArmColor'))
    writeBrickColor(out, 'LeftLegColor', safeGet(inst, 'LeftLegColor'))
    writeBrickColor(out, 'RightLegColor', safeGet(inst, 'RightLegColor'))
    writeBrickColor(out, 'TorsoColor', safeGet(inst, 'TorsoColor'))
    writeColor3(out, 'HeadColor3', safeGet(inst, 'HeadColor3'))
    writeColor3(out, 'LeftArmColor3', safeGet(inst, 'LeftArmColor3'))
    writeColor3(out, 'RightArmColor3', safeGet(inst, 'RightArmColor3'))
    writeColor3(out, 'LeftLegColor3', safeGet(inst, 'LeftLegColor3'))
    writeColor3(out, 'RightLegColor3', safeGet(inst, 'RightLegColor3'))
    writeColor3(out, 'TorsoColor3', safeGet(inst, 'TorsoColor3'))
end

CLASS_HANDLERS.Model = function(out, inst, state)
    if not state or not state.referentOf then
        return
    end
    local pp = safeGet(inst, 'PrimaryPart')
    if pp ~= nil then
        writeRef(out, 'PrimaryPart', state.referentOf[pp])
    end
end

CLASS_HANDLERS.Beam = function(out, inst, _state)
    writeContentProps(out, inst, 'Beam')
    writeColorSequence(out, 'Color', safeGet(inst, 'Color'))
    writeNumberSequence(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeFloat(out, 'LightEmission', safeGet(inst, 'LightEmission'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeFloat(out, 'TextureLength', safeGet(inst, 'TextureLength'))
    writeFloat(out, 'TextureSpeed', safeGet(inst, 'TextureSpeed'))
    writeFloat(out, 'TextureStudsPerUnit', safeGet(inst, 'TextureStudsPerUnit'))
    writeFloat(out, 'Width0', safeGet(inst, 'Width0'))
    writeFloat(out, 'Width1', safeGet(inst, 'Width1'))
    writeFloat(out, 'CurveSize0', safeGet(inst, 'CurveSize0'))
    writeFloat(out, 'CurveSize1', safeGet(inst, 'CurveSize1'))
    writeBool(out, 'FaceCamera', safeGet(inst, 'FaceCamera'))
    writeBool(out, 'Capped', safeGet(inst, 'Capped'))
    writeInt(out, 'Segments', safeGet(inst, 'Segments'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local p0 = safeGet(inst, 'Attachment0')
    local p1 = safeGet(inst, 'Attachment1')
    if _state and _state.referentOf then
        writeRef(out, 'Attachment0', _state.referentOf[p0])
        writeRef(out, 'Attachment1', _state.referentOf[p1])
    end
end

CLASS_HANDLERS.Trail = function(out, inst, _state)
    writeContentProps(out, inst, 'Trail')
    writeColorSequence(out, 'Color', safeGet(inst, 'Color'))
    writeNumberSequence(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeFloat(out, 'LightEmission', safeGet(inst, 'LightEmission'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeFloat(out, 'Lifetime', safeGet(inst, 'Lifetime'))
    writeFloat(out, 'MaxLength', safeGet(inst, 'MaxLength'))
    writeFloat(out, 'MinLength', safeGet(inst, 'MinLength'))
    writeFloat(out, 'TextureLength', safeGet(inst, 'TextureLength'))
    writeFloat(out, 'TextureSpeed', safeGet(inst, 'TextureSpeed'))
    writeFloat(out, 'TextureStudsPerUnit', safeGet(inst, 'TextureStudsPerUnit'))
    writeFloat(out, 'WidthScale', safeGet(inst, 'WidthScale'))
    writeBool(out, 'FaceCamera', safeGet(inst, 'FaceCamera'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local p0 = safeGet(inst, 'Attachment0')
    local p1 = safeGet(inst, 'Attachment1')
    if _state and _state.referentOf then
        writeRef(out, 'Attachment0', _state.referentOf[p0])
        writeRef(out, 'Attachment1', _state.referentOf[p1])
    end
end

CLASS_HANDLERS.VectorForce = function(out, inst, state)
    writeVector3(out, 'Force', safeGet(inst, 'Force'))
    writeBool(out, 'ApplyAtCenterOfMass', safeGet(inst, 'ApplyAtCenterOfMass'))
    local ra = safeGet(inst, 'RelativeTo')
    local raVal = (type(ra) == 'table') and safeGet(ra, 'Value') or nil
    if type(raVal) == 'number' then
        writeToken(out, 'RelativeTo', raVal)
    end
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.Torque = function(out, inst, state)
    writeVector3(out, 'Torque', safeGet(inst, 'Torque'))
    local ra = safeGet(inst, 'RelativeTo')
    local raVal = (type(ra) == 'table') and safeGet(ra, 'Value') or nil
    if type(raVal) == 'number' then
        writeToken(out, 'RelativeTo', raVal)
    end
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.RopeConstraint = function(out, inst, state)
    writeFloat(out, 'Length', safeGet(inst, 'Length'))
    writeFloat(out, 'Restitution', safeGet(inst, 'Restitution'))
    writeBool(out, 'Visible', safeGet(inst, 'Visible'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
end

CLASS_HANDLERS.HingeConstraint = function(out, inst, state)
    writeBool(out, 'LimitsEnabled', safeGet(inst, 'LimitsEnabled'))
    writeFloat(out, 'LowerAngle', safeGet(inst, 'LowerAngle'))
    writeFloat(out, 'UpperAngle', safeGet(inst, 'UpperAngle'))
    local at = safeGet(inst, 'ActuatorType')
    local atVal = (type(at) == 'table') and safeGet(at, 'Value') or nil
    if type(atVal) == 'number' then
        writeToken(out, 'ActuatorType', atVal)
    end
    writeFloat(out, 'AngularVelocity', safeGet(inst, 'AngularVelocity'))
    writeFloat(out, 'Torque', safeGet(inst, 'Torque'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
end

CLASS_HANDLERS.BallSocketConstraint = function(out, inst, state)
    writeBool(out, 'LimitsEnabled', safeGet(inst, 'LimitsEnabled'))
    writeFloat(out, 'UpperAngle', safeGet(inst, 'UpperAngle'))
    writeBool(out, 'TwistLimitsEnabled', safeGet(inst, 'TwistLimitsEnabled'))
    writeFloat(out, 'TwistLowerAngle', safeGet(inst, 'TwistLowerAngle'))
    writeFloat(out, 'TwistUpperAngle', safeGet(inst, 'TwistUpperAngle'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
end

CLASS_HANDLERS.PrismaticConstraint = function(out, inst, state)
    writeBool(out, 'LimitsEnabled', safeGet(inst, 'LimitsEnabled'))
    writeFloat(out, 'LowerLimit', safeGet(inst, 'LowerLimit'))
    writeFloat(out, 'UpperLimit', safeGet(inst, 'UpperLimit'))
    writeFloat(out, 'Restitution', safeGet(inst, 'Restitution'))
    local at = safeGet(inst, 'ActuatorType')
    local atVal = (type(at) == 'table') and safeGet(at, 'Value') or nil
    if type(atVal) == 'number' then
        writeToken(out, 'ActuatorType', atVal)
    end
    writeFloat(out, 'Velocity', safeGet(inst, 'Velocity'))
    writeFloat(out, 'Force', safeGet(inst, 'Force'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
end

CLASS_HANDLERS.SpringConstraint = function(out, inst, state)
    writeInt(out, 'Coils', safeGet(inst, 'Coils'))
    writeFloat(out, 'Damping', safeGet(inst, 'Damping'))
    writeFloat(out, 'FreeLength', safeGet(inst, 'FreeLength'))
    writeBool(out, 'LimitsEnabled', safeGet(inst, 'LimitsEnabled'))
    writeFloat(out, 'MaxForce', safeGet(inst, 'MaxForce'))
    writeFloat(out, 'MaxVelocity', safeGet(inst, 'MaxVelocity'))
    writeFloat(out, 'MinLength', safeGet(inst, 'MinLength'))
    writeFloat(out, 'Radius', safeGet(inst, 'Radius'))
    writeFloat(out, 'Stiffness', safeGet(inst, 'Stiffness'))
    writeBool(out, 'Visible', safeGet(inst, 'Visible'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local a0 = safeGet(inst, 'Attachment0')
    local a1 = safeGet(inst, 'Attachment1')
    if state and state.referentOf then
        writeRef(out, 'Attachment0', state.referentOf[a0])
        writeRef(out, 'Attachment1', state.referentOf[a1])
    end
end

CLASS_HANDLERS.Highlight = function(out, inst, state)
    writeColor3(out, 'FillColor', safeGet(inst, 'FillColor'))
    writeFloat(out, 'FillTransparency', safeGet(inst, 'FillTransparency'))
    writeColor3(out, 'OutlineColor', safeGet(inst, 'OutlineColor'))
    writeFloat(out, 'OutlineTransparency', safeGet(inst, 'OutlineTransparency'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    local ad = safeGet(inst, 'Adornee')
    if state and state.referentOf and ad then
        writeRef(out, 'Adornee', state.referentOf[ad])
    end
end

CLASS_HANDLERS.ProximityPrompt = function(out, inst, _state)
    writeString(out, 'ActionText', safeGet(inst, 'ActionText'))
    writeString(out, 'ObjectText', safeGet(inst, 'ObjectText'))
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'HoldDuration', safeGet(inst, 'HoldDuration'))
    writeFloat(out, 'MaxActivationDistance', safeGet(inst, 'MaxActivationDistance'))
    writeBool(out, 'RequiresLineOfSight', safeGet(inst, 'RequiresLineOfSight'))
    writeBool(out, 'SingleAction', safeGet(inst, 'SingleAction'))
    local kk = safeGet(inst, 'KeyboardKeyCode')
    local kkVal = (type(kk) == 'table') and safeGet(kk, 'Value') or nil
    if type(kkVal) == 'number' then
        writeToken(out, 'KeyboardKeyCode', kkVal)
    end
    local gk = safeGet(inst, 'GamepadKeyCode')
    local gkVal = (type(gk) == 'table') and safeGet(gk, 'Value') or nil
    if type(gkVal) == 'number' then
        writeToken(out, 'GamepadKeyCode', gkVal)
    end
end

CLASS_HANDLERS.ClickDetector = function(out, inst, _state)
    writeFloat(out, 'MaxActivationDistance', safeGet(inst, 'MaxActivationDistance'))
end

CLASS_HANDLERS.SurfaceLight = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Brightness', safeGet(inst, 'Brightness'))
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeBool(out, 'Shadows', safeGet(inst, 'Shadows'))
    writeFloat(out, 'Range', safeGet(inst, 'Range'))
    writeFloat(out, 'Angle', safeGet(inst, 'Angle'))
    local f = safeGet(inst, 'Face')
    local fVal = (type(f) == 'table') and safeGet(f, 'Value') or nil
    if type(fVal) == 'number' then
        writeToken(out, 'Face', fVal)
    end
end

CLASS_HANDLERS.PointLight = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Brightness', safeGet(inst, 'Brightness'))
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeBool(out, 'Shadows', safeGet(inst, 'Shadows'))
    writeFloat(out, 'Range', safeGet(inst, 'Range'))
end

CLASS_HANDLERS.SpotLight = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeFloat(out, 'Brightness', safeGet(inst, 'Brightness'))
    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeBool(out, 'Shadows', safeGet(inst, 'Shadows'))
    writeFloat(out, 'Range', safeGet(inst, 'Range'))
    writeFloat(out, 'Angle', safeGet(inst, 'Angle'))
    local f = safeGet(inst, 'Face')
    local fVal = (type(f) == 'table') and safeGet(f, 'Value') or nil
    if type(fVal) == 'number' then
        writeToken(out, 'Face', fVal)
    end
end

CLASS_HANDLERS.ScreenGui = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeBool(out, 'ResetOnSpawn', safeGet(inst, 'ResetOnSpawn'))
    writeBool(out, 'IgnoreGuiInset', safeGet(inst, 'IgnoreGuiInset'))
    writeInt(out, 'DisplayOrder', safeGet(inst, 'DisplayOrder'))
    local z = safeGet(inst, 'ZIndexBehavior')
    local zVal = (type(z) == 'table') and safeGet(z, 'Value') or nil
    if type(zVal) == 'number' then
        writeToken(out, 'ZIndexBehavior', zVal)
    end
end

CLASS_HANDLERS.BillboardGui = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeBool(out, 'AlwaysOnTop', safeGet(inst, 'AlwaysOnTop'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeFloat(out, 'MaxDistance', safeGet(inst, 'MaxDistance'))
    writeVector2(out, 'Size', safeGet(inst, 'Size'))
    writeVector2(out, 'SizeOffset', safeGet(inst, 'SizeOffset'))
    writeVector3(out, 'StudsOffset', safeGet(inst, 'StudsOffset'))
    writeVector3(out, 'StudsOffsetWorldSpace', safeGet(inst, 'StudsOffsetWorldSpace'))
    writeFloat(out, 'ZOffset', safeGet(inst, 'ZOffset'))
    local ad = safeGet(inst, 'Adornee')
    if _state and _state.referentOf and ad then
        writeRef(out, 'Adornee', _state.referentOf[ad])
    end
end

CLASS_HANDLERS.SurfaceGui = function(out, inst, _state)
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
    writeBool(out, 'Active', safeGet(inst, 'Active'))
    writeVector2(out, 'CanvasSize', safeGet(inst, 'CanvasSize'))
    writeFloat(out, 'LightInfluence', safeGet(inst, 'LightInfluence'))
    writeInt(out, 'PixelsPerStud', safeGet(inst, 'PixelsPerStud'))
    writeFloat(out, 'ZOffset', safeGet(inst, 'ZOffset'))
    local f = safeGet(inst, 'Face')
    local fVal = (type(f) == 'table') and safeGet(f, 'Value') or nil
    if type(fVal) == 'number' then
        writeToken(out, 'Face', fVal)
    end
    local ad = safeGet(inst, 'Adornee')
    if _state and _state.referentOf and ad then
        writeRef(out, 'Adornee', _state.referentOf[ad])
    end
end

CLASS_HANDLERS.Seat = function(out, inst, _state)
    writeBool(out, 'Disabled', safeGet(inst, 'Disabled'))
    local sh = safeGet(inst, 'Shape')
    local shVal = (type(sh) == 'table') and safeGet(sh, 'Value') or nil
    if type(shVal) == 'number' then
        writeToken(out, 'Shape', shVal)
    end
end

CLASS_HANDLERS.VehicleSeat = function(out, inst, _state)
    writeBool(out, 'Disabled', safeGet(inst, 'Disabled'))
    writeBool(out, 'HeadsUpDisplay', safeGet(inst, 'HeadsUpDisplay'))
    writeFloat(out, 'MaxSpeed', safeGet(inst, 'MaxSpeed'))
    writeFloat(out, 'Torque', safeGet(inst, 'Torque'))
    writeFloat(out, 'TurnSpeed', safeGet(inst, 'TurnSpeed'))
end

VALUE_BASE_HANDLERS.ObjectValue = function(out, _inst, state, v)
    local ref = state.referentOf[v]
    writeRef(out, 'Value', ref)
end

VALUE_BASE_HANDLERS.BoolValue = function(out, _inst, _state, v)
    writeBool(out, 'Value', v)
end

VALUE_BASE_HANDLERS.IntValue = function(out, _inst, _state, v)
    if type(v) == 'number' then
        writeInt(out, 'Value', math.floor(v))
    end
end

VALUE_BASE_HANDLERS.NumberValue = function(out, _inst, _state, v)
    if type(v) == 'number' then
        writeDouble(out, 'Value', v)
    end
end

VALUE_BASE_HANDLERS.FloatValue = function(out, _inst, _state, v)
    if type(v) == 'number' then
        writeDouble(out, 'Value', v)
    end
end

VALUE_BASE_HANDLERS.StringValue = function(out, _inst, _state, v)
    writeString(out, 'Value', v)
end

VALUE_BASE_HANDLERS.Color3Value = function(out, _inst, _state, v)
    writeColor3(out, 'Value', v)
end

VALUE_BASE_HANDLERS.Vector3Value = function(out, _inst, _state, v)
    writeVector3(out, 'Value', v)
end

VALUE_BASE_HANDLERS.Vector2Value = function(out, _inst, _state, v)
    writeVector2(out, 'Value', v)
end

VALUE_BASE_HANDLERS.CFrameValue = function(out, _inst, _state, v)
    writeCoordinateFrame(out, 'Value', v)
end

VALUE_BASE_HANDLERS.UDimValue = function(out, _inst, _state, v)
    writeUDim(out, 'Value', v)
end

VALUE_BASE_HANDLERS.UDim2Value = function(out, _inst, _state, v)
    writeUDim2(out, 'Value', v)
end

VALUE_BASE_HANDLERS.NumberSequenceValue = function(out, _inst, _state, v)
    writeNumberSequence(out, 'Value', v)
end

VALUE_BASE_HANDLERS.ColorSequenceValue = function(out, _inst, _state, v)
    writeColorSequence(out, 'Value', v)
end

VALUE_BASE_HANDLERS.NumberRangeValue = function(out, _inst, _state, v)
    writeNumberRange(out, 'Value', v)
end

VALUE_BASE_HANDLERS.RayValue = function(out, _inst, _state, v)
    writeString(out, 'Value', tostring(v))
end

VALUE_BASE_HANDLERS.RectValue = function(out, _inst, _state, v)
    writeRect(out, 'Value', v)
end

local function writeAttributes(out, inst)
    if not _G.CONFIG.exportAttributes then
        return
    end

    local ok, attrs = pcall(function()
        return inst:GetAttributes()
    end)

    if not ok or type(attrs) ~= 'table' then
        return
    end

    for attrName, attrValue in pairs(attrs) do
        if type(attrName) == 'string' and attrName ~= '' then
            writeAny(out, attrName, attrValue)
        end
    end
end

local SKIP_PROPERTIES = {
    Parent = true,
    ClassName = true,
    UniqueId = true,
    MeshId = true,
    TextureId = true,
    TextureID = true,
    MeshContent = true,
    TextureContent = true,
    SoundId = true,
    AudioContent = true,
    Graphic = true,
}

local function writeSpecProperties(out, inst, state)
    local list = KNOWN_PROPERTIES[inst.ClassName]
    if type(list) ~= 'table' then
        return
    end
    for _, prop in ipairs(list) do
        if not SKIP_PROPERTIES[prop] then
            if not BASE_PART_WRITE_PROPS[prop] or not inst:IsA('BasePart') then
                writeAny(out, prop, safeGet(inst, prop), state)
            end
        end
    end
end

local function writeKnownProperties(out, inst, state)
    writeAny(out, 'Name', safeGet(inst, 'Name'), state)

    if inst:IsA('BasePart') then
        writeBasePartProperties(out, inst)
    end

    if inst:IsA('GuiObject') then
        writeGuiObjectProperties(out, inst)
    end

    local classHandler = CLASS_HANDLERS[inst.ClassName]
    if classHandler then
        classHandler(out, inst, state)
    end

    writeSpecProperties(out, inst, state)
end

local function writeScriptSource(out, inst)
    local src = tryDecompileScript(inst)
    if src then
        writeString(out, 'Source', src)
    end
end

CLASS_HANDLERS.LocalScript = function(out, inst, _state)
    writeScriptSource(out, inst)
end

CLASS_HANDLERS.ModuleScript = function(out, inst, _state)
    writeScriptSource(out, inst)
end

CLASS_HANDLERS.Script = function(out, inst, _state)
    writeScriptSource(out, inst)
end

local function writeValueBaseValue(out, inst, state)
    if not inst:IsA('ValueBase') then
        return
    end

    local v = safeGet(inst, 'Value')
    if v == nil then
        return
    end

    local handler = VALUE_BASE_HANDLERS[inst.ClassName]
    if handler then
        handler(out, inst, state, v)
        return
    end

    writeAny(out, 'Value', v)
end

local function writeItem(out, inst, state)
    if state.visited[inst] then
        return
    end
    state.visited[inst] = true

    if not shouldExportInstance(inst) then
        if _G.CONFIG.includeChildrenOfFiltered then
            for _, child in ipairs(inst:GetChildren()) do
                writeItem(out, child, state)
            end
        end
        return
    end

    state.processed = (state.processed or 0) + 1
    if state.progress then
        local every = state.progressEvery or 25
        if (state.processed == 1) or (state.processed % every == 0) or (state.processed == state.total) then
            state.progress.update(
                state.processed,
                state.total,
                string.format('Exporting %d/%d (%.1f%%)', state.processed, state.total, (state.total > 0 and (state.processed / state.total) or 0) * 100)
            )
            if state.console then
                local name = safeGet(inst, 'Name')
                local className = inst.ClassName
                state.console.setCurrent(string.format('Exporting: %s (%s)', name or '?', className))
            end
        end
    end

    local referent = state.referentOf[inst]
    if referent == nil then
        state.dynamicId = (state.dynamicId or state.total or 0) + 1
        referent = 'RBX' .. tostring(state.dynamicId)
        state.referentOf[inst] = referent
    end

    local className = inst.ClassName
    push(out, "<Item class=\"" .. xmlEscape(className) .. "\" referent=\"" .. referent .. "\">")
    push(out, "<Properties>")
    writeKnownProperties(out, inst, state)
    writeValueBaseValue(out, inst, state)
    writeAttributes(out, inst)
    push(out, "</Properties>")

    for _, child in ipairs(inst:GetChildren()) do
        writeItem(out, child, state)
    end

    push(out, "</Item>")
end

local function exportToXml(root)
    local out = {}
    PLAYER_NAME_SET = buildPlayerNameSet()
    push(out, "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    push(out, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
    push(out, '<External>null</External>')
    local pb = createProgressBar()
    local console = _G.CONFIG.showConsole and createMiniConsole() or nil
    pb.update(0, 1, 'Indexing instances...')
    if console then
        console.log('Indexing instances...')
    end

    local referentOf = {}
    local visited = {}
    local ordered = {}
    local function collect(inst)
        if visited[inst] then
            return
        end
        visited[inst] = true
        if not shouldExportInstance(inst) then
            if _G.CONFIG.includeChildrenOfFiltered then
                for _, child in ipairs(inst:GetChildren()) do
                    collect(child)
                end
            end
            return
        end
        ordered[#ordered + 1] = inst
        for _, child in ipairs(inst:GetChildren()) do
            collect(child)
        end
    end

    local exportRoots = root:GetChildren()
    for _, child in ipairs(exportRoots) do
        if shouldExportService(child) then
            collect(child)
        elseif _G.CONFIG.includeChildrenOfFiltered then
            for _, grandChild in ipairs(child:GetChildren()) do
                collect(grandChild)
            end
        end
    end

    for i, inst in ipairs(ordered) do
        referentOf[inst] = 'RBX' .. tostring(i)
    end

    local total = #ordered
    pb.update(0, total, string.format('Exporting 0/%d (0.0%%)', total))

    local state = {
        visited = {},
        processed = 0,
        total = total,
        progress = pb,
        console = console,
        progressEvery = 25,
        referentOf = referentOf,
    }

    for _, child in ipairs(root:GetChildren()) do
        if shouldExportService(child) then
            writeItem(out, child, state)
        elseif _G.CONFIG.includeChildrenOfFiltered then
            for _, grandChild in ipairs(child:GetChildren()) do
                writeItem(out, grandChild, state)
            end
        end
    end
    push(out, "</roblox>")

    pb.update(total, total, 'Done')
    if console then
        console.done('Finished export')
    end
    pb.destroy()
    if console then
        console.destroy()
    end

    return table.concat(out, "\n")
end

local ok, xml = pcall(function()
    return exportToXml(_G.CONFIG.root)
end)

if ok and type(xml) == 'string' then
    if _G.CONFIG.saveToFile then
        local fileName = _G.CONFIG.fileName or (getgamename() .. '_' .. os.time() .. '.rblx')
        if not fileName:find('%.rblx$') then
            fileName = fileName .. '.rblx'
        end
        pcall(function()
            writefile(fileName, xml)
        end)
        notify('SaveInstance', 'Saved to ' .. fileName, 5)
    end
    setclipboard(xml)
    notify('SaveInstance', 'Exported ' .. #xml .. ' bytes to clipboard', 3)
else
    local errMsg = tostring(xml)
    notify('SaveInstance', 'Export failed: ' .. errMsg, 5)
end
