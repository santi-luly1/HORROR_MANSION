--The only objetive for this is to reexport the types for LLS
local onyxui = require(script.Parent._Index["imavafe_onyx-ui@1.0.2"]["onyx-ui"])

--------------------------------------------------------------------
--- Types reexport (LLS wasn't happy)
--------------------------------------------------------------------
export type Theme = onyxui.Theme
export type ThemeSpec = onyxui.ThemeSpec

export type BaseProps = onyxui.BaseProps
export type TextProps = onyxui.TextProps
export type FrameProps = onyxui.FrameProps
export type BadgeProps = onyxui.BadgeProps
export type AvatarProps = onyxui.AvatarProps
export type AutoScalerProps = onyxui.AutoScalerProps
export type BaseButtonProps = onyxui.BaseButtonProps
export type ButtonProps = onyxui.ButtonProps
export type CardProps = onyxui.CardProps
export type CheckboxProps = onyxui.CheckboxProps
export type DividerProps = onyxui.DividerProps
export type GroupProps = onyxui.GroupProps
export type HeadingProps = onyxui.HeadingProps
export type IconProps = onyxui.IconProps
export type IconButtonProps = onyxui.IconButtonProps
export type IconTextProps = onyxui.IconTextProps
export type ImageProps = onyxui.ImageProps
export type ProgressBarProps = onyxui.ProgressBarProps
export type ScrollerProps = onyxui.ScrollerProps
export type SwitchProps = onyxui.SwitchProps
export type TextInputProps = onyxui.TextInputProps
export type TextAreaProps = onyxui.TextAreaProps
export type TitleBarProps = onyxui.TitleBarProps
export type TextSwapProps = onyxui.TextSwapProps
export type IconSwapProps = onyxui.IconSwapProps
export type SliderProps = onyxui.SliderProps
export type TabsProps = onyxui.TabsProps

export type CornerProps = onyxui.CornerProps
export type PaddingProps = onyxui.PaddingProps
export type StrokeProps = onyxui.StrokeProps
export type GradientProps = onyxui.GradientProps
export type AspectProps = onyxui.AspectProps
export type ScaleProps = onyxui.ScaleProps

export type ListProps = onyxui.ListProps
export type GridProps = onyxui.GridProps
export type TableProps = onyxui.TableProps
export type PageProps = onyxui.PageProps
export type FlexProps = onyxui.FlexProps

export type SizeLimitProps = onyxui.SizeLimitProps
export type TextSizeLimitProps = onyxui.TextSizeLimitProps

return onyxui
