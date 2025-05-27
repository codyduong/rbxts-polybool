-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
--
-- polybool - Boolean operations on polygons (union, intersection, etc)
-- by Sean Connelly (@velipso), https://sean.fun
-- adapted to roblox by Cody Duong (@codyduong), https://codyduong.dev
--
-- Project Home: https://github.com/codyduong/rbxts-polybool
-- SPDX-License-Identifier: 0BSD
--
-- rbxts       version: 0.1.2     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.2)
-- polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
--
-- eslint-disable @typescript-eslint/explicit-function-return-type 
local _Intersecter = TS.import(script, script.Parent, "Intersecter")
local Intersecter = _Intersecter.Intersecter
local copySegmentBool = _Intersecter.copySegmentBool
local SegmentSelector = TS.import(script, script.Parent, "SegmentSelector").SegmentSelector
local _SegmentChainer = TS.import(script, script.Parent, "SegmentChainer")
local SegmentChainer = _SegmentChainer.SegmentChainer
local segmentsToReceiver = _SegmentChainer.segmentsToReceiver
local SQRT1_2 = 0.7071067811865476
local ShapeCombined
local Shape
do
	Shape = setmetatable({}, {
		__tostring = function()
			return "Shape"
		end,
	})
	Shape.__index = Shape
	function Shape.new(...)
		local self = setmetatable({}, Shape)
		return self:constructor(...) or self
	end
	function Shape:constructor(geo, segments, log)
		if segments == nil then
			segments = nil
		end
		if log == nil then
			log = nil
		end
		self.pathState = {
			kind = "beginPath",
		}
		self.saveStack = {}
		self.matrix = { 1, 0, 0, 1, 0, 0 }
		self.geo = geo
		self.log = log
		if segments then
			self.resultState = {
				state = "seg",
				segments = segments,
			}
		else
			self.resultState = {
				state = "new",
				selfIntersect = Intersecter.new(true, self.geo, self.log),
			}
		end
	end
	function Shape:setTransform(a, b, c, d, e, f)
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		self.matrix = { a, b, c, d, e, f }
		return self
	end
	function Shape:resetTransform()
		self.matrix = { 1, 0, 0, 1, 0, 0 }
		return self
	end
	function Shape:getTransform()
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		local _binding = self.matrix
		local a = _binding[1]
		local b = _binding[2]
		local c = _binding[3]
		local d = _binding[4]
		local e = _binding[5]
		local f = _binding[6]
		return {
			a = a,
			b = b,
			c = c,
			d = d,
			e = e,
			f = f,
		}
	end
	function Shape:transform(a, b, c, d, e, f)
		local _binding = self.matrix
		local a0 = _binding[1]
		local b0 = _binding[2]
		local c0 = _binding[3]
		local d0 = _binding[4]
		local e0 = _binding[5]
		local f0 = _binding[6]
		self.matrix = { a0 * a + c0 * b, b0 * a + d0 * b, a0 * c + c0 * d, b0 * c + d0 * d, a0 * e + c0 * f + e0, b0 * e + d0 * f + f0 }
		return self
	end
	function Shape:rotate(angle)
		local cos = math.cos(angle)
		local sin = math.sin(angle)
		local _binding = self.matrix
		local a0 = _binding[1]
		local b0 = _binding[2]
		local c0 = _binding[3]
		local d0 = _binding[4]
		local e0 = _binding[5]
		local f0 = _binding[6]
		self.matrix = { a0 * cos + c0 * sin, b0 * cos + d0 * sin, c0 * cos - a0 * sin, d0 * cos - b0 * sin, e0, f0 }
		return self
	end
	function Shape:rotateDeg(angle)
		local ang = ((angle % 360) + 360) % 360
		if ang == 0 then
			return self
		end
		local cos = 0
		local sin = 0
		if ang == 90 then
			sin = 1
		elseif ang == 180 then
			cos = -1
		elseif ang == 270 then
			sin = -1
		elseif ang == 45 then
			sin = SQRT1_2
			cos = sin
		elseif ang == 135 then
			sin = SQRT1_2
			cos = -SQRT1_2
		elseif ang == 225 then
			sin = -SQRT1_2
			cos = sin
		elseif ang == 315 then
			cos = SQRT1_2
			sin = -SQRT1_2
		elseif ang == 30 then
			cos = math.sqrt(3) / 2
			sin = 0.5
		elseif ang == 60 then
			cos = 0.5
			sin = math.sqrt(3) / 2
		elseif ang == 120 then
			cos = -0.5
			sin = math.sqrt(3) / 2
		elseif ang == 150 then
			cos = -math.sqrt(3) / 2
			sin = 0.5
		elseif ang == 210 then
			cos = -math.sqrt(3) / 2
			sin = -0.5
		elseif ang == 240 then
			cos = -0.5
			sin = -math.sqrt(3) / 2
		elseif ang == 300 then
			cos = 0.5
			sin = -math.sqrt(3) / 2
		elseif ang == 330 then
			cos = math.sqrt(3) / 2
			sin = -0.5
		else
			local rad = (math.pi * ang) / 180
			cos = math.cos(rad)
			sin = math.sin(rad)
		end
		local _binding = self.matrix
		local a0 = _binding[1]
		local b0 = _binding[2]
		local c0 = _binding[3]
		local d0 = _binding[4]
		local e0 = _binding[5]
		local f0 = _binding[6]
		self.matrix = { a0 * cos + c0 * sin, b0 * cos + d0 * sin, c0 * cos - a0 * sin, d0 * cos - b0 * sin, e0, f0 }
		return self
	end
	function Shape:scale(sx, sy)
		local _binding = self.matrix
		local a0 = _binding[1]
		local b0 = _binding[2]
		local c0 = _binding[3]
		local d0 = _binding[4]
		local e0 = _binding[5]
		local f0 = _binding[6]
		self.matrix = { a0 * sx, b0 * sx, c0 * sy, d0 * sy, e0, f0 }
		return self
	end
	function Shape:translate(tx, ty)
		local _binding = self.matrix
		local a0 = _binding[1]
		local b0 = _binding[2]
		local c0 = _binding[3]
		local d0 = _binding[4]
		local e0 = _binding[5]
		local f0 = _binding[6]
		self.matrix = { a0, b0, c0, d0, a0 * tx + c0 * ty + e0, b0 * tx + d0 * ty + f0 }
		return self
	end
	function Shape:save()
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		local _saveStack = self.saveStack
		local _arg0 = {
			matrix = self.matrix,
		}
		table.insert(_saveStack, _arg0)
		return self
	end
	function Shape:restore()
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		local _exp = self.saveStack
		-- ▼ Array.pop ▼
		local _length = #_exp
		local _result = _exp[_length]
		_exp[_length] = nil
		-- ▲ Array.pop ▲
		local s = _result
		if s then
			self.matrix = s.matrix
		end
		return self
	end
	function Shape:transformPoint(x, y)
		local _binding = self.matrix
		local a = _binding[1]
		local b = _binding[2]
		local c = _binding[3]
		local d = _binding[4]
		local e = _binding[5]
		local f = _binding[6]
		return { a * x + c * y + e, b * x + d * y + f }
	end
	function Shape:beginPath()
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		self.resultState.selfIntersect:beginPath()
		return self:endPath()
	end
	function Shape:moveTo(x, y)
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		if self.pathState.kind ~= "beginPath" then
			self:beginPath()
		end
		local current = self:transformPoint(x, y)
		self.pathState = {
			kind = "moveTo",
			start = current,
			current = current,
		}
		return self
	end
	function Shape:lineTo(x, y)
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		if self.pathState.kind ~= "moveTo" then
			error("PolyBool: Must call moveTo prior to calling lineTo")
		end
		local current = self:transformPoint(x, y)
		self.resultState.selfIntersect:addLine(self.pathState.current, current)
		self.pathState.current = current
		return self
	end
	function Shape:rect(x, y, width, height)
		return self:moveTo(x, y):lineTo(x + width, y):lineTo(x + width, y + height):lineTo(x, y + height):closePath():moveTo(x, y)
	end
	function Shape:bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		if self.pathState.kind ~= "moveTo" then
			error("PolyBool: Must call moveTo prior to calling bezierCurveTo")
		end
		local current = self:transformPoint(x, y)
		self.resultState.selfIntersect:addCurve(self.pathState.current, self:transformPoint(cp1x, cp1y), self:transformPoint(cp2x, cp2y), current)
		self.pathState.current = current
		return self
	end
	function Shape:closePath()
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		-- close with a line if needed
		if self.pathState.kind == "moveTo" and not self.geo:isEqualVec2(self.pathState.start, self.pathState.current) then
			self.resultState.selfIntersect:addLine(self.pathState.current, self.pathState.start)
			self.pathState.current = self.pathState.start
		end
		self.resultState.selfIntersect:closePath()
		return self:endPath()
	end
	function Shape:endPath()
		if self.resultState.state ~= "new" then
			error("PolyBool: Cannot change shape after using it in an operation")
		end
		self.pathState = {
			kind = "beginPath",
		}
		return self
	end
	function Shape:selfIntersect()
		if self.resultState.state == "new" then
			self.resultState = {
				state = "seg",
				segments = self.resultState.selfIntersect:calculate(),
			}
		end
		return self.resultState.segments
	end
	function Shape:segments()
		if self.resultState.state ~= "reg" then
			local seg = self:selfIntersect()
			self.resultState = {
				state = "reg",
				segments = seg,
				regions = SegmentChainer(seg, self.geo, self.log),
			}
		end
		return self.resultState.regions
	end
	function Shape:output(receiver, matrix)
		if matrix == nil then
			matrix = { 1, 0, 0, 1, 0, 0 }
		end
		return segmentsToReceiver(self:segments(), self.geo, receiver, matrix)
	end
	function Shape:combine(shape)
		local int = Intersecter.new(false, self.geo, self.log)
		for _, seg in self:selfIntersect() do
			int:addSegment(copySegmentBool(seg, self.log), true)
		end
		for _, seg in shape:selfIntersect() do
			int:addSegment(copySegmentBool(seg, self.log), false)
		end
		return ShapeCombined.new(int:calculate(), self.geo, self.log)
	end
end
do
	ShapeCombined = setmetatable({}, {
		__tostring = function()
			return "ShapeCombined"
		end,
	})
	ShapeCombined.__index = ShapeCombined
	function ShapeCombined.new(...)
		local self = setmetatable({}, ShapeCombined)
		return self:constructor(...) or self
	end
	function ShapeCombined:constructor(segments, geo, log)
		if log == nil then
			log = nil
		end
		self.geo = geo
		self.segments = segments
		self.log = log
	end
	function ShapeCombined:union()
		return Shape.new(self.geo, SegmentSelector:union(self.segments, self.log), self.log)
	end
	function ShapeCombined:intersect()
		return Shape.new(self.geo, SegmentSelector:intersect(self.segments, self.log), self.log)
	end
	function ShapeCombined:difference()
		return Shape.new(self.geo, SegmentSelector:difference(self.segments, self.log), self.log)
	end
	function ShapeCombined:differenceRev()
		return Shape.new(self.geo, SegmentSelector:differenceRev(self.segments, self.log), self.log)
	end
	function ShapeCombined:xor()
		return Shape.new(self.geo, SegmentSelector:xor(self.segments, self.log), self.log)
	end
end
return {
	Shape = Shape,
	ShapeCombined = ShapeCombined,
}
