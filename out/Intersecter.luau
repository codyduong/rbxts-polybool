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
-- eslint-disable @typescript-eslint/strict-boolean-expressions 
local _Segment = TS.import(script, script.Parent, "Segment")
local SegmentLine = _Segment.SegmentLine
local SegmentCurve = _Segment.SegmentCurve
local segmentsIntersect = _Segment.segmentsIntersect
local ArrayX = TS.import(script, script.Parent, "ArrayX").default
local SegmentBoolBase
do
	SegmentBoolBase = setmetatable({}, {
		__tostring = function()
			return "SegmentBoolBase"
		end,
	})
	SegmentBoolBase.__index = SegmentBoolBase
	function SegmentBoolBase.new(...)
		local self = setmetatable({}, SegmentBoolBase)
		return self:constructor(...) or self
	end
	function SegmentBoolBase:constructor(data, fill, closed, log)
		if fill == nil then
			fill = nil
		end
		if closed == nil then
			closed = false
		end
		if log == nil then
			log = nil
		end
		self.otherFill = nil
		local _result = log
		if _result ~= nil then
			_result = _result:segmentId()
		end
		local _condition = _result
		if _condition == nil then
			_condition = -1
		end
		self.id = _condition
		self.data = data
		local _object = {}
		local _left = "above"
		local _result_1 = fill
		if _result_1 ~= nil then
			_result_1 = _result_1.above
		end
		local _condition_1 = _result_1
		if _condition_1 == nil then
			_condition_1 = nil
		end
		_object[_left] = _condition_1
		local _left_1 = "below"
		local _result_2 = fill
		if _result_2 ~= nil then
			_result_2 = _result_2.below
		end
		local _condition_2 = _result_2
		if _condition_2 == nil then
			_condition_2 = nil
		end
		_object[_left_1] = _condition_2
		self.myFill = _object
		self.closed = closed
	end
end
local SegmentBoolLine
do
	local super = SegmentBoolBase
	SegmentBoolLine = setmetatable({}, {
		__tostring = function()
			return "SegmentBoolLine"
		end,
		__index = super,
	})
	SegmentBoolLine.__index = SegmentBoolLine
	function SegmentBoolLine.new(...)
		local self = setmetatable({}, SegmentBoolLine)
		return self:constructor(...) or self
	end
	function SegmentBoolLine:constructor(...)
		super.constructor(self, ...)
	end
end
local SegmentBoolCurve
do
	local super = SegmentBoolBase
	SegmentBoolCurve = setmetatable({}, {
		__tostring = function()
			return "SegmentBoolCurve"
		end,
		__index = super,
	})
	SegmentBoolCurve.__index = SegmentBoolCurve
	function SegmentBoolCurve.new(...)
		local self = setmetatable({}, SegmentBoolCurve)
		return self:constructor(...) or self
	end
	function SegmentBoolCurve:constructor(...)
		super.constructor(self, ...)
	end
end
local function copySegmentBool(seg, log)
	if TS.instanceof(seg, SegmentBoolLine) then
		return SegmentBoolLine.new(seg.data, seg.myFill, seg.closed, log)
	elseif TS.instanceof(seg, SegmentBoolCurve) then
		return SegmentBoolCurve.new(seg.data, seg.myFill, seg.closed, log)
	end
	error("PolyBool: Unknown SegmentBool in copySegmentBool")
end
local EventBool
do
	EventBool = setmetatable({}, {
		__tostring = function()
			return "EventBool"
		end,
	})
	EventBool.__index = EventBool
	function EventBool.new(...)
		local self = setmetatable({}, EventBool)
		return self:constructor(...) or self
	end
	function EventBool:constructor(isStart, p, seg, primary)
		self.status = nil
		self.isStart = isStart
		self.p = p
		self.seg = seg
		self.primary = primary
	end
end
local ListBool
do
	ListBool = setmetatable({}, {
		__tostring = function()
			return "ListBool"
		end,
	})
	ListBool.__index = ListBool
	function ListBool.new(...)
		local self = setmetatable({}, ListBool)
		return self:constructor(...) or self
	end
	function ListBool:constructor()
		self.nodes = {}
	end
	function ListBool:remove(node)
		local _nodes = self.nodes
		local _node = node
		local i = (table.find(_nodes, _node) or 0) - 1
		if i >= 0 then
			ArrayX.splice(self.nodes, i, 1)
		end
	end
	function ListBool:getIndex(node)
		local _nodes = self.nodes
		local _node = node
		return (table.find(_nodes, _node) or 0) - 1
	end
	function ListBool:isEmpty()
		return #self.nodes <= 0
	end
	function ListBool:getHead()
		return self.nodes[1]
	end
	function ListBool:removeHead()
		table.remove(self.nodes, 1)
	end
	function ListBool:insertBefore(node, check)
		self:findTransition(node, check).insert(node)
	end
	function ListBool:findTransition(node, check)
		-- bisect to find the transition point
		local compare = function(a, b)
			return check(b) - check(a)
		end
		local i = 0
		local high = #self.nodes
		while i < high do
			local mid = bit32.arshift((i + high), 1)
			if compare(self.nodes[mid + 1], node) > 0 then
				high = mid
			else
				i = mid + 1
			end
		end
		local _object = {}
		local _left = "before"
		local _result
		if i <= 0 then
			_result = nil
		else
			local _condition = self.nodes[i]
			if _condition == nil then
				_condition = nil
			end
			_result = _condition
		end
		_object[_left] = _result
		local _left_1 = "after"
		local _condition = self.nodes[i + 1]
		if _condition == nil then
			_condition = nil
		end
		_object[_left_1] = _condition
		_object.insert = function(node)
			ArrayX.splice(self.nodes, i, 0, node)
			return node
		end
		return _object
	end
end
local Intersecter
do
	Intersecter = setmetatable({}, {
		__tostring = function()
			return "Intersecter"
		end,
	})
	Intersecter.__index = Intersecter
	function Intersecter.new(...)
		local self = setmetatable({}, Intersecter)
		return self:constructor(...) or self
	end
	function Intersecter:constructor(selfIntersection, geo, log)
		if log == nil then
			log = nil
		end
		self.events = ListBool.new()
		self.status = ListBool.new()
		self.currentPath = {}
		self.selfIntersection = selfIntersection
		self.geo = geo
		self.log = log
	end
	function Intersecter:compareEvents(aStart, a1, a2, aSeg, bStart, b1, b2, bSeg)
		-- compare the selected points first
		local comp = self.geo:compareVec2(a1, b1)
		if comp ~= 0 then
			return comp
		end
		-- the selected points are the same
		if TS.instanceof(aSeg, SegmentLine) and TS.instanceof(bSeg, SegmentLine) and self.geo:isEqualVec2(a2, b2) then
			-- if the non-selected points are the same too...
			return 0
		end
		if aStart ~= bStart then
			-- if one is a start and the other isn't...
			return if aStart then 1 else -1
		end
		return self:compareSegments(bSeg, aSeg)
	end
	function Intersecter:addEvent(ev)
		self.events:insertBefore(ev, function(here)
			if here == ev then
				return 0
			end
			return self:compareEvents(ev.isStart, ev.p, ev.other.p, ev.seg.data, here.isStart, here.p, here.other.p, here.seg.data)
		end)
	end
	function Intersecter:divideEvent(ev, t, p)
		local _result = self.log
		if _result ~= nil then
			_result:segmentDivide(ev.seg, p)
		end
		local _binding = ev.seg.data:split({ t })
		local left = _binding[1]
		local right = _binding[2]
		-- set the *exact* intersection point
		left:setEnd(p)
		right:setStart(p)
		local ns = if TS.instanceof(right, SegmentLine) then SegmentBoolLine.new(right, ev.seg.myFill, ev.seg.closed, self.log) elseif TS.instanceof(right, SegmentCurve) then SegmentBoolCurve.new(right, ev.seg.myFill, ev.seg.closed, self.log) else nil
		if not ns then
			error("PolyBool: Unknown segment data in divideEvent")
		end
		-- slides an end backwards
		--   (start)------------(end)    to:
		--   (start)---(end)
		self.events:remove(ev.other)
		ev.seg.data = left
		local _result_1 = self.log
		if _result_1 ~= nil then
			_result_1:segmentChop(ev.seg)
		end
		ev.other.p = p
		self:addEvent(ev.other)
		return self:addSegment(ns, ev.primary)
	end
	function Intersecter:beginPath()
		self.currentPath = {}
	end
	function Intersecter:closePath()
		for _, seg in self.currentPath do
			seg.closed = true
		end
	end
	function Intersecter:addSegment(seg, primary)
		local evStart = EventBool.new(true, seg.data:start(), seg, primary)
		local _data = seg.data
		local evEnd = EventBool.new(false, _data["end"](_data), seg, primary)
		evStart.other = evEnd
		evEnd.other = evStart
		self:addEvent(evStart)
		self:addEvent(evEnd)
		return evStart
	end
	function Intersecter:addLine(from, to, primary)
		if primary == nil then
			primary = true
		end
		local f = self.geo:compareVec2(from, to)
		if f == 0 then
			-- points are equal, so we have a zero-length segment
			return nil
		end
		local seg = SegmentBoolLine.new(SegmentLine.new(if f < 0 then from else to, if f < 0 then to else from, self.geo), nil, false, self.log)
		local _exp = self.currentPath
		table.insert(_exp, seg)
		self:addSegment(seg, primary)
	end
	function Intersecter:addCurve(from, c1, c2, to, primary)
		if primary == nil then
			primary = true
		end
		local original = SegmentCurve.new(from, c1, c2, to, self.geo)
		local curves = original:split(original:inflectionTValues())
		for _, curve in curves do
			local f = self.geo:compareVec2(curve:start(), curve["end"](curve))
			if f == 0 then
				-- points are equal AFTER splitting... this only happens for zero-length segments
				continue
			end
			-- convert horizontal/vertical curves to lines
			local line = curve:toLine()
			if line then
				self:addLine(line.p0, line.p1, primary)
			else
				local seg = SegmentBoolCurve.new(if f < 0 then curve else curve:reverse(), nil, false, self.log)
				local _exp = self.currentPath
				table.insert(_exp, seg)
				self:addSegment(seg, primary)
			end
		end
	end
	function Intersecter:compareSegments(seg1, seg2)
		-- TODO:
		--  This is where some of the curve instability comes from... we need to reliably sort
		--  segments, but this is surprisingly hard when it comes to curves.
		--
		--  The easy case is something like:
		--
		--             C   A - - - D
		--               \
		--                 \
		--                   B
		--  A is clearly above line C-B, which is easily calculated... however, once curves are
		--  introduced, it's not so obvious without using some heuristic which will fail at times.
		--
		local A = seg1:start()
		local B = seg2:start2()
		local C = seg2:start()
		if seg2:pointOn(A) then
			-- A intersects seg2 somehow (possibly sharing a start point, or maybe just splitting it)
			--
			--   AC - - - - D
			--      \
			--        \
			--          B
			--
			-- so grab seg1's second point (D) instead
			A = seg1:start2()
			if seg2:pointOn(A) then
				if TS.instanceof(seg1, SegmentLine) then
					if TS.instanceof(seg2, SegmentLine) then
						-- oh... D is on the line too... so these are the same
						return 0
					end
					if TS.instanceof(seg2, SegmentCurve) then
						A = seg1:point(0.5)
					end
				end
				if TS.instanceof(seg1, SegmentCurve) then
					A = seg1["end"](seg1)
				end
			end
			if TS.instanceof(seg2, SegmentCurve) then
				if self.geo:snap0(A[1] - C[1]) == 0 and self.geo:snap0(B[1] - C[1]) == 0 then
					-- seg2 is a curve, but the tangent line (C-B) at the start point is vertical, and
					-- collinear with A... so... just sort based on the Y values I guess?
					return math.sign(C[2] - A[2])
				end
			end
		else
			if TS.instanceof(seg2, SegmentCurve) then
				-- find seg2's position at A[0] and see if it's above or below A[1]
				local y = seg2:mapXtoY(A[1], true)
				if y ~= false then
					return math.sign(y - A[2])
				end
			end
			if TS.instanceof(seg1, SegmentCurve) then
				-- unfortunately, in order to sort against curved segments, we need to check the
				-- intersection point... this means a lot more intersection tests, but I'm not sure how else
				-- to sort correctly
				local i = segmentsIntersect(seg1, seg2, true)
				if i and i.kind == "tValuePairs" then
					-- find the intersection point on seg1
					for _, pair in i.tValuePairs do
						local t = self.geo:snap01(pair[1])
						if t > 0 and t < 1 then
							B = seg1:point(t)
							break
						end
					end
				end
			end
		end
		-- fallthrough to this calculation which determines if A is on one side or another of C-B
		local _binding = A
		local Ax = _binding[1]
		local Ay = _binding[2]
		local _binding_1 = B
		local Bx = _binding_1[1]
		local By = _binding_1[2]
		local _binding_2 = C
		local Cx = _binding_2[1]
		local Cy = _binding_2[2]
		return math.sign((Bx - Ax) * (Cy - Ay) - (By - Ay) * (Cx - Ax))
	end
	function Intersecter:statusFindSurrounding(ev)
		return self.status:findTransition(ev, function(here)
			if ev == here then
				return 0
			end
			local c = self:compareSegments(ev.seg.data, here.seg.data)
			return if c == 0 then -1 else c
		end)
	end
	function Intersecter:checkIntersection(ev1, ev2)
		-- returns the segment equal to ev1, or undefined if nothing equal
		local seg1 = ev1.seg
		local seg2 = ev2.seg
		local _result = self.log
		if _result ~= nil then
			_result:checkIntersection(seg1, seg2)
		end
		local i = segmentsIntersect(seg1.data, seg2.data, false)
		if i == nil then
			-- no intersections
			return nil
		elseif i.kind == "tRangePairs" then
			-- segments are parallel or coincident
			local _binding = i
			local _binding_1 = _binding.tStart
			local tA1 = _binding_1[1]
			local tB1 = _binding_1[2]
			local _binding_2 = _binding.tEnd
			local tA2 = _binding_2[1]
			local tB2 = _binding_2[2]
			if (tA1 == 1 and tA2 == 1 and tB1 == 0 and tB2 == 0) or (tA1 == 0 and tA2 == 0 and tB1 == 1 and tB2 == 1) then
				return nil
			end
			if tA1 == 0 and tA2 == 1 and tB1 == 0 and tB2 == 1 then
				return ev2
			end
			local a1 = seg1.data:start()
			local _data = seg1.data
			local a2 = _data["end"](_data)
			local _data_1 = seg2.data
			local b2 = _data_1["end"](_data_1)
			if tA1 == 0 and tB1 == 0 then
				if tA2 == 1 then
					--  (a1)---(a2)
					--  (b1)----------(b2)
					self:divideEvent(ev2, tB2, a2)
				else
					--  (a1)----------(a2)
					--  (b1)---(b2)
					self:divideEvent(ev1, tA2, b2)
				end
				return ev2
			elseif tB1 > 0 and tB1 < 1 then
				if tA2 == 1 and tB2 == 1 then
					--         (a1)---(a2)
					--  (b1)----------(b2)
					self:divideEvent(ev2, tB1, a1)
				else
					-- make a2 equal to b2
					if tA2 == 1 then
						--         (a1)---(a2)
						--  (b1)-----------------(b2)
						self:divideEvent(ev2, tB2, a2)
					else
						--         (a1)----------(a2)
						--  (b1)----------(b2)
						self:divideEvent(ev1, tA2, b2)
					end
					--         (a1)---(a2)
					--  (b1)----------(b2)
					self:divideEvent(ev2, tB1, a1)
				end
			end
			return nil
		elseif i.kind == "tValuePairs" then
			if #i.tValuePairs <= 0 then
				return nil
			end
			-- process a single intersection
			-- skip intersections where endpoints meet
			local minPair = i.tValuePairs[1]
			do
				local j = 1
				local _shouldIncrement = false
				while true do
					if _shouldIncrement then
						j += 1
					else
						_shouldIncrement = true
					end
					if not (j < #i.tValuePairs and ((minPair[1] == 0 and minPair[2] == 0) or (minPair[1] == 0 and minPair[2] == 1) or (minPair[1] == 1 and minPair[2] == 0) or (minPair[1] == 1 and minPair[2] == 1))) then
						break
					end
					minPair = i.tValuePairs[j + 1]
				end
			end
			local _binding = minPair
			local tA = _binding[1]
			local tB = _binding[2]
			-- even though *in theory* seg1.data.point(tA) === seg2.data.point(tB), that isn't exactly
			-- correct in practice because intersections aren't exact... so we need to calculate a single
			-- intersection point that everyone can share
			local _result_1
			if tB == 0 then
				_result_1 = seg2.data:start()
			else
				local _result_2
				if tB == 1 then
					local _data = seg2.data
					_result_2 = _data["end"](_data)
				else
					local _result_3
					if tA == 0 then
						_result_3 = seg1.data:start()
					else
						local _result_4
						if tA == 1 then
							local _data = seg1.data
							_result_4 = _data["end"](_data)
						else
							_result_4 = seg1.data:point(tA)
						end
						_result_3 = _result_4
					end
					_result_2 = _result_3
				end
				_result_1 = _result_2
			end
			local p = _result_1
			-- is A divided between its endpoints? (exclusive)
			if tA > 0 and tA < 1 then
				self:divideEvent(ev1, tA, p)
			end
			-- is B divided between its endpoints? (exclusive)
			if tB > 0 and tB < 1 then
				self:divideEvent(ev2, tB, p)
			end
			return nil
		end
		error("PolyBool: Unknown intersection type")
	end
	function Intersecter:calculate()
		local segments = {}
		while not self.events:isEmpty() do
			local ev = self.events:getHead()
			local _result = self.log
			if _result ~= nil then
				_result:vert(ev.p[1])
			end
			if ev.isStart then
				local _result_1 = self.log
				if _result_1 ~= nil then
					_result_1:segmentNew(ev.seg, ev.primary)
				end
				local surrounding = self:statusFindSurrounding(ev)
				local above = surrounding.before
				local below = surrounding.after
				local _result_2 = self.log
				if _result_2 ~= nil then
					_result_2:tempStatus(ev.seg, if above then above.seg else false, if below then below.seg else false)
				end
				local checkBothIntersections = function()
					if above then
						local eve = self:checkIntersection(ev, above)
						if eve then
							return eve
						end
					end
					if below then
						return self:checkIntersection(ev, below)
					end
					return nil
				end
				local eve = checkBothIntersections()
				if eve then
					-- ev and eve are equal
					-- we'll keep eve and throw away ev
					-- merge ev.seg's fill information into eve.seg
					if self.selfIntersection then
						local toggle
						if ev.seg.myFill.below == nil then
							toggle = ev.seg.closed
						else
							toggle = ev.seg.myFill.above ~= ev.seg.myFill.below
						end
						-- merge two segments that belong to the same polygon
						-- think of this as sandwiching two segments together, where
						-- `eve.seg` is the bottom -- this will cause the above fill flag to
						-- toggle
						if toggle then
							eve.seg.myFill.above = not eve.seg.myFill.above
						end
					else
						-- merge two segments that belong to different polygons
						-- each segment has distinct knowledge, so no special logic is
						-- needed
						-- note that this can only happen once per segment in this phase,
						-- because we are guaranteed that all self-intersections are gone
						eve.seg.otherFill = ev.seg.myFill
					end
					local _result_3 = self.log
					if _result_3 ~= nil then
						_result_3:segmentUpdate(eve.seg)
					end
					self.events:remove(ev.other)
					self.events:remove(ev)
				end
				if self.events:getHead() ~= ev then
					-- something was inserted before us in the event queue, so loop back
					-- around and process it before continuing
					local _result_3 = self.log
					if _result_3 ~= nil then
						_result_3:rewind(ev.seg)
					end
					continue
				end
				--
				-- calculate fill flags
				--
				if self.selfIntersection then
					local toggle
					if ev.seg.myFill.below == nil then
						-- if we are new then we toggle if we're part of a closed path
						toggle = ev.seg.closed
					else
						-- we are a segment that has previous knowledge from a division
						-- calculate toggle
						toggle = ev.seg.myFill.above ~= ev.seg.myFill.below
					end
					-- next, calculate whether we are filled below us
					if not below then
						-- if nothing is below us, then we're not filled
						ev.seg.myFill.below = false
					else
						-- otherwise, we know the answer -- it's the same if whatever is
						-- below us is filled above it
						ev.seg.myFill.below = below.seg.myFill.above
					end
					-- since now we know if we're filled below us, we can calculate
					-- whether we're filled above us by applying toggle to whatever is
					-- below us
					ev.seg.myFill.above = if toggle then not ev.seg.myFill.below else ev.seg.myFill.below
				else
					-- now we fill in any missing transition information, since we are
					-- all-knowing at this point
					if ev.seg.otherFill == nil then
						-- if we don't have other information, then we need to figure out if
						-- we're inside the other polygon
						local inside
						if not below then
							-- if nothing is below us, then we're not filled
							inside = false
						else
							-- otherwise, something is below us
							-- so copy the below segment's other polygon's above
							if ev.primary == below.primary then
								if below.seg.otherFill == nil then
									error("PolyBool: Unexpected state of otherFill (undefined)")
								end
								inside = below.seg.otherFill.above
							else
								inside = below.seg.myFill.above
							end
						end
						ev.seg.otherFill = {
							above = inside,
							below = inside,
						}
					end
				end
				local _result_3 = self.log
				if _result_3 ~= nil then
					_result_3:status(ev.seg, if above then above.seg else false, if below then below.seg else false)
				end
				-- insert the status and remember it for later removal
				ev.other.status = surrounding.insert(ev)
			else
				-- end
				local st = ev.status
				if st == nil then
					error("PolyBool: Zero-length segment detected; your epsilon is " .. "probably too small or too large")
				end
				-- removing the status will create two new adjacent edges, so we'll need
				-- to check for those
				local i = self.status:getIndex(st)
				if i > 0 and i < #self.status.nodes - 1 then
					local before = self.status.nodes[i]
					local after = self.status.nodes[i + 2]
					self:checkIntersection(before, after)
				end
				local _result_1 = self.log
				if _result_1 ~= nil then
					_result_1:statusRemove(st.seg)
				end
				-- remove the status
				self.status:remove(st)
				-- if we've reached this point, we've calculated everything there is to
				-- know, so save the segment for reporting
				if not ev.primary then
					-- make sure `seg.myFill` actually points to the primary polygon
					-- though
					if not ev.seg.otherFill then
						error("PolyBool: Unexpected state of otherFill (undefined)")
					end
					local s = ev.seg.myFill
					ev.seg.myFill = ev.seg.otherFill
					ev.seg.otherFill = s
				end
				local _seg = ev.seg
				table.insert(segments, _seg)
			end
			-- remove the event and continue
			self.events:removeHead()
		end
		local _result = self.log
		if _result ~= nil then
			_result:done()
		end
		return segments
	end
end
return {
	copySegmentBool = copySegmentBool,
	SegmentBoolBase = SegmentBoolBase,
	SegmentBoolLine = SegmentBoolLine,
	SegmentBoolCurve = SegmentBoolCurve,
	EventBool = EventBool,
	ListBool = ListBool,
	Intersecter = Intersecter,
}
