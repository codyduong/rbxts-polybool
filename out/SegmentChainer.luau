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
-- rbxts       version: 0.1.1     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.1)
-- polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
--
-- eslint-disable @typescript-eslint/explicit-function-return-type 
-- eslint-disable @typescript-eslint/strict-boolean-expressions 
-- eslint-disable prettier/prettier 
local _Segment = TS.import(script, script.Parent, "Segment")
local SegmentLine = _Segment.SegmentLine
local SegmentCurve = _Segment.SegmentCurve
local ArrayX = TS.import(script, script.Parent, "ArrayX").default
--
-- converts a list of segments into a list of regions, while also removing
-- unnecessary verticies
--
local function joinLines(seg1, seg2, geo)
	if geo:isCollinear(seg1.p0, seg1.p1, seg2.p1) then
		return SegmentLine.new(seg1.p0, seg2.p1, geo)
	end
	return false
end
local function joinCurves(seg1, seg2, geo)
	if geo:isCollinear(seg1.p2, seg1.p3, seg2.p1) then
		local dx = seg2.p1[1] - seg1.p2[1]
		local dy = seg2.p1[2] - seg1.p2[2]
		local t = if math.abs(dx) > math.abs(dy) then (seg1.p3[1] - seg1.p2[1]) / dx else (seg1.p3[2] - seg1.p2[2]) / dy
		local ts = geo:snap01(t)
		if ts ~= 0 and ts ~= 1 then
			local ns = SegmentCurve.new(seg1.p0, { seg1.p0[1] + (seg1.p1[1] - seg1.p0[1]) / t, seg1.p0[2] + (seg1.p1[2] - seg1.p0[2]) / t }, { seg2.p2[1] - (t * (seg2.p3[1] - seg2.p2[1])) / (1 - t), seg2.p2[2] - (t * (seg2.p3[2] - seg2.p2[2])) / (1 - t) }, seg2.p3, geo)
			-- double check that if we split at T, we get seg1/seg2 back
			local _binding = ns:split({ t })
			local left = _binding[1]
			local right = _binding[2]
			if left:isEqual(seg1) and right:isEqual(seg2) then
				return ns
			end
		end
	end
	return false
end
local function joinSegments(seg1, seg2, geo)
	if seg1 == seg2 then
		return false
	end
	if TS.instanceof(seg1, SegmentLine) and TS.instanceof(seg2, SegmentLine) then
		return joinLines(seg1, seg2, geo)
	end
	if TS.instanceof(seg1, SegmentCurve) and TS.instanceof(seg2, SegmentCurve) then
		return joinCurves(seg1, seg2, geo)
	end
	return false
end
local function SegmentChainer(segments, geo, log)
	local closedChains = {}
	local openChains = {}
	local regions = {}
	for _, segb in segments do
		local seg = segb.data
		local closed = segb.closed
		local chains = if closed then closedChains else openChains
		local pt1 = seg:start()
		local pt2 = seg["end"](seg)
		local reverseChain = function(index)
			local _result = log
			if _result ~= nil then
				_result:chainReverse(index, closed)
			end
			local newChain = {}
			for _1, seg in chains[index + 1].segs do
				local _arg0 = seg:reverse()
				table.insert(newChain, 1, _arg0)
			end
			chains[index + 1] = {
				segs = newChain,
				fill = not chains[index + 1].fill,
			}
			return newChain
		end
		if TS.instanceof(seg, SegmentLine) and geo:isEqualVec2(pt1, pt2) then
			print("PolyBool: Warning: Zero-length segment detected; your epsilon is " .. "probably too small or too large")
			continue
		end
		local _result = log
		if _result ~= nil then
			_result:chainStart({
				seg = seg,
				fill = not not segb.myFill.above,
			}, closed)
		end
		-- search for two chains that this segment matches
		local firstMatch = {
			index = 0,
			matchesHead = false,
			matchesPt1 = false,
		}
		local secondMatch = {
			index = 0,
			matchesHead = false,
			matchesPt1 = false,
		}
		local nextMatch = firstMatch
		local function setMatch(index, matchesHead, matchesPt1)
			-- return true if we've matched twice
			if nextMatch then
				nextMatch.index = index
				nextMatch.matchesHead = matchesHead
				nextMatch.matchesPt1 = matchesPt1
			end
			if nextMatch == firstMatch then
				nextMatch = secondMatch
				return false
			end
			nextMatch = nil
			return true
		end
		for i = 0, #chains - 1 do
			local chain = chains[i + 1].segs
			local head = chain[1]:start()
			local _1 = chain[#chain]
			local tail = _1["end"](_1)
			if geo:isEqualVec2(head, pt1) then
				if setMatch(i, true, true) then
					break
				end
			elseif geo:isEqualVec2(head, pt2) then
				if setMatch(i, true, false) then
					break
				end
			elseif geo:isEqualVec2(tail, pt1) then
				if setMatch(i, false, true) then
					break
				end
			elseif geo:isEqualVec2(tail, pt2) then
				if setMatch(i, false, false) then
					break
				end
			end
		end
		if nextMatch == firstMatch then
			-- we didn't match anything, so create a new chain
			local fill = not not segb.myFill.above
			local _arg0 = {
				segs = { seg },
				fill = fill,
			}
			table.insert(chains, _arg0)
			local _result_1 = log
			if _result_1 ~= nil then
				_result_1:chainNew({
					seg = seg,
					fill = fill,
				}, closed)
			end
		elseif nextMatch == secondMatch then
			-- we matched a single chain
			local index = firstMatch.index
			local _result_1 = log
			if _result_1 ~= nil then
				_result_1:chainMatch(index, closed)
			end
			-- add the other point to the apporpriate end
			local _binding = chains[index + 1]
			local chain = _binding.segs
			local fill = _binding.fill
			if firstMatch.matchesHead then
				if firstMatch.matchesPt1 then
					seg = seg:reverse()
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainAddHead(index, {
							seg = seg,
							fill = fill,
						}, closed)
					end
					local _seg = seg
					table.insert(chain, 1, _seg)
				else
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainAddHead(index, {
							seg = seg,
							fill = fill,
						}, closed)
					end
					local _seg = seg
					table.insert(chain, 1, _seg)
				end
			else
				if firstMatch.matchesPt1 then
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainAddTail(index, {
							seg = seg,
							fill = fill,
						}, closed)
					end
					local _seg = seg
					table.insert(chain, _seg)
				else
					seg = seg:reverse()
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainAddTail(index, {
							seg = seg,
							fill = fill,
						}, closed)
					end
					local _seg = seg
					table.insert(chain, _seg)
				end
			end
			-- simplify chain
			if firstMatch.matchesHead then
				local next_ = chain[2]
				local newSeg = joinSegments(seg, next_, geo)
				if newSeg then
					table.remove(chain, 1)
					chain[1] = newSeg
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainSimplifyHead(index, {
							seg = newSeg,
							fill = fill,
						}, closed)
					end
				end
			else
				local next_ = chain[#chain - 1]
				local newSeg = joinSegments(next_, seg, geo)
				if newSeg then
					chain[#chain] = nil
					chain[#chain] = newSeg
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainSimplifyTail(index, {
							seg = newSeg,
							fill = fill,
						}, closed)
					end
				end
			end
			-- check for closed chain
			if closed then
				local finalChain = chain
				local segS = finalChain[1]
				local segE = finalChain[#finalChain]
				if #finalChain > 0 and geo:isEqualVec2(segS:start(), segE["end"](segE)) then
					-- see if chain is clockwise
					local winding = 0
					local last = finalChain[1]:start()
					for _1, seg in finalChain do
						local here = seg["end"](seg)
						winding += here[2] * last[1] - here[1] * last[2]
						last = here
					end
					-- this assumes Cartesian coordinates (Y is positive going up)
					local isClockwise = winding < 0
					if isClockwise == fill then
						finalChain = reverseChain(index)
						segS = finalChain[1]
						segE = finalChain[#finalChain]
					end
					local newStart = joinSegments(segE, segS, geo)
					if newStart then
						finalChain[#finalChain] = nil
						finalChain[1] = newStart
						local _result_2 = log
						if _result_2 ~= nil then
							_result_2:chainSimplifyClose(index, {
								seg = newStart,
								fill = fill,
							}, closed)
						end
					end
					-- we have a closed chain!
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainClose(index, closed)
					end
					ArrayX.splice(chains, index, 1)
					local _finalChain = finalChain
					table.insert(regions, _finalChain)
				end
			end
		else
			-- otherwise, we matched two chains, so we need to combine those chains together
			local appendChain = function(index1, index2)
				-- index1 gets index2 appended to it, and index2 is removed
				local _binding = chains[index1 + 1]
				local chain1 = _binding.segs
				local fill = _binding.fill
				local _binding_1 = chains[index2 + 1]
				local chain2 = _binding_1.segs
				-- add seg to chain1's tail
				local _result_1 = log
				if _result_1 ~= nil then
					_result_1:chainAddTail(index1, {
						seg = seg,
						fill = fill,
					}, closed)
				end
				local _seg = seg
				table.insert(chain1, _seg)
				-- simplify chain1's tail
				local next_ = chain1[#chain1 - 1]
				local newEnd = joinSegments(next_, seg, geo)
				if newEnd then
					chain1[#chain1] = nil
					chain1[#chain1] = newEnd
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainSimplifyTail(index1, {
							seg = newEnd,
							fill = fill,
						}, closed)
					end
				end
				-- simplify chain2's head
				local tail = chain1[#chain1]
				local head = chain2[1]
				local newJoin = joinSegments(tail, head, geo)
				if newJoin then
					table.remove(chain2, 1)
					chain1[#chain1] = newJoin
					local _result_2 = log
					if _result_2 ~= nil then
						_result_2:chainSimplifyJoin(index1, index2, {
							seg = newJoin,
							fill = fill,
						}, closed)
					end
				end
				local _result_2 = log
				if _result_2 ~= nil then
					_result_2:chainJoin(index1, index2, closed)
				end
				local _array = {}
				local _length = #_array
				local _chain1Length = #chain1
				table.move(chain1, 1, _chain1Length, _length + 1, _array)
				_length += _chain1Length
				table.move(chain2, 1, #chain2, _length + 1, _array)
				chains[index1 + 1].segs = _array
				ArrayX.splice(chains, index2, 1)
			end
			local F = firstMatch.index
			local S = secondMatch.index
			local _result_1 = log
			if _result_1 ~= nil then
				_result_1:chainConnect(F, S, closed)
			end
			-- reverse the shorter chain, if needed
			local reverseF = #chains[F + 1].segs < #chains[S + 1].segs
			if firstMatch.matchesHead then
				if secondMatch.matchesHead then
					if reverseF then
						if not firstMatch.matchesPt1 then
							-- <<<< F <<<< <-- >>>> S >>>>
							seg = seg:reverse()
						end
						-- <<<< F <<<< --> >>>> S >>>>
						reverseChain(F)
						-- >>>> F >>>> --> >>>> S >>>>
						appendChain(F, S)
					else
						if firstMatch.matchesPt1 then
							-- <<<< F <<<< --> >>>> S >>>>
							seg = seg:reverse()
						end
						-- <<<< F <<<< <-- >>>> S >>>>
						reverseChain(S)
						-- <<<< F <<<< <-- <<<< S <<<<   logically same as:
						-- >>>> S >>>> --> >>>> F >>>>
						appendChain(S, F)
					end
				else
					if firstMatch.matchesPt1 then
						-- <<<< F <<<< --> >>>> S >>>>
						seg = seg:reverse()
					end
					-- <<<< F <<<< <-- <<<< S <<<<   logically same as:
					-- >>>> S >>>> --> >>>> F >>>>
					appendChain(S, F)
				end
			else
				if secondMatch.matchesHead then
					if not firstMatch.matchesPt1 then
						-- >>>> F >>>> <-- >>>> S >>>>
						seg = seg:reverse()
					end
					-- >>>> F >>>> --> >>>> S >>>>
					appendChain(F, S)
				else
					if reverseF then
						if firstMatch.matchesPt1 then
							-- >>>> F >>>> --> <<<< S <<<<
							seg = seg:reverse()
						end
						-- >>>> F >>>> <-- <<<< S <<<<
						reverseChain(F)
						-- <<<< F <<<< <-- <<<< S <<<<   logically same as:
						-- >>>> S >>>> --> >>>> F >>>>
						appendChain(S, F)
					else
						if not firstMatch.matchesPt1 then
							-- >>>> F >>>> <-- <<<< S <<<<
							seg = seg:reverse()
						end
						-- >>>> F >>>> --> <<<< S <<<<
						reverseChain(S)
						-- >>>> F >>>> --> >>>> S >>>>
						appendChain(F, S)
					end
				end
			end
		end
	end
	for _, _binding in openChains do
		local segs = _binding.segs
		table.insert(regions, segs)
	end
	return regions
end
local function segmentsToReceiver(segments, geo, receiver, matrix)
	local _binding = matrix
	local a = _binding[1]
	local b = _binding[2]
	local c = _binding[3]
	local d = _binding[4]
	local e = _binding[5]
	local f = _binding[6]
	receiver.beginPath()
	for _, region in segments do
		if #region <= 0 then
			continue
		end
		for i = 0, #region - 1 do
			local seg = region[i + 1]
			if i == 0 then
				local _binding_1 = seg:start()
				local p0x = _binding_1[1]
				local p0y = _binding_1[2]
				receiver.moveTo(a * p0x + c * p0y + e, b * p0x + d * p0y + f)
			end
			if TS.instanceof(seg, SegmentLine) then
				local _binding_1 = seg.p1
				local p1x = _binding_1[1]
				local p1y = _binding_1[2]
				receiver.lineTo(a * p1x + c * p1y + e, b * p1x + d * p1y + f)
			elseif TS.instanceof(seg, SegmentCurve) then
				local _binding_1 = seg.p1
				local p1x = _binding_1[1]
				local p1y = _binding_1[2]
				local _binding_2 = seg.p2
				local p2x = _binding_2[1]
				local p2y = _binding_2[2]
				local _binding_3 = seg.p3
				local p3x = _binding_3[1]
				local p3y = _binding_3[2]
				receiver.bezierCurveTo(a * p1x + c * p1y + e, b * p1x + d * p1y + f, a * p2x + c * p2y + e, b * p2x + d * p2y + f, a * p3x + c * p3y + e, b * p3x + d * p3y + f)
			else
				error("PolyBool: Unknown segment instance")
			end
		end
		local first = region[1]
		local last = region[#region]
		if geo:isEqualVec2(first:start(), last["end"](last)) then
			receiver.closePath()
		end
	end
	return receiver
end
return {
	joinLines = joinLines,
	joinCurves = joinCurves,
	joinSegments = joinSegments,
	SegmentChainer = SegmentChainer,
	segmentsToReceiver = segmentsToReceiver,
}
