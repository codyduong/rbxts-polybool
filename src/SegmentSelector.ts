//
// polybool - Boolean operations on polygons (union, intersection, etc)
// by Sean Connelly (@velipso), https://sean.fun
// adapted to roblox by Cody Duong (@codyduong), https://codyduong.dev
//
// Project Home: https://github.com/codyduong/rbxts-polybool
// SPDX-License-Identifier: 0BSD
//
// rbxts       version: 0.1.1     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.1)
// polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
//

/* eslint-disable @typescript-eslint/explicit-function-return-type */
/* eslint-disable @typescript-eslint/strict-boolean-expressions */

import { type SegmentBool, SegmentBoolLine, SegmentBoolCurve } from "./Intersecter";
import type BuildLog from "./BuildLog";

//
// filter a list of segments based on boolean operations
//
// `select` is reserved
function selectt(segments: SegmentBool[], selection: number[], log: BuildLog | undefined): SegmentBool[] {
  const result: SegmentBool[] = [];
  for (const seg of segments) {
    const index =
      (seg.myFill.above ? 8 : 0) +
      (seg.myFill.below ? 4 : 0) +
      (seg.otherFill && seg.otherFill.above ? 2 : 0) +
      (seg.otherFill && seg.otherFill.below ? 1 : 0);
    const flags = selection[index];
    const above = (flags & 1) !== 0; // bit 1 if filled above
    const below = (flags & 2) !== 0; // bit 2 if filled below
    if ((!seg.closed && flags !== 0) || (seg.closed && above !== below)) {
      // copy the segment to the results, while also calculating the fill status
      const fill = { above, below };
      if (seg instanceof SegmentBoolLine) {
        result.push(new SegmentBoolLine(seg.data, fill, seg.closed, log));
      } else if (seg instanceof SegmentBoolCurve) {
        result.push(new SegmentBoolCurve(seg.data, fill, seg.closed, log));
      } else {
        error("PolyBool: Unknown SegmentBool type in SegmentSelector");
      }
    }
  }
  log?.selected(result);
  return result;
}

export class SegmentSelector {
  // prettier-ignore
  static union(segments: SegmentBool[], log: BuildLog | undefined) {
    // primary | secondary
    // above1 below1 above2 below2    Keep?               Value
    //    0      0      0      0   =>   yes if open         4
    //    0      0      0      1   =>   yes filled below    2
    //    0      0      1      0   =>   yes filled above    1
    //    0      0      1      1   =>   no                  0
    //    0      1      0      0   =>   yes filled below    2
    //    0      1      0      1   =>   yes filled below    2
    //    0      1      1      0   =>   no                  0
    //    0      1      1      1   =>   no                  0
    //    1      0      0      0   =>   yes filled above    1
    //    1      0      0      1   =>   no                  0
    //    1      0      1      0   =>   yes filled above    1
    //    1      0      1      1   =>   no                  0
    //    1      1      0      0   =>   no                  0
    //    1      1      0      1   =>   no                  0
    //    1      1      1      0   =>   no                  0
    //    1      1      1      1   =>   no                  0
    return selectt(
      segments,
      [
        4, 2, 1, 0,
        2, 2, 0, 0,
        1, 0, 1, 0,
        0, 0, 0, 0
      ],
      log,
    );
  }

  // prettier-ignore
  static intersect(segments: SegmentBool[], log: BuildLog | undefined) {
    // primary & secondary
    // above1 below1 above2 below2    Keep?               Value
    //    0      0      0      0   =>   no                  0
    //    0      0      0      1   =>   no                  0
    //    0      0      1      0   =>   no                  0
    //    0      0      1      1   =>   yes if open         4
    //    0      1      0      0   =>   no                  0
    //    0      1      0      1   =>   yes filled below    2
    //    0      1      1      0   =>   no                  0
    //    0      1      1      1   =>   yes filled below    2
    //    1      0      0      0   =>   no                  0
    //    1      0      0      1   =>   no                  0
    //    1      0      1      0   =>   yes filled above    1
    //    1      0      1      1   =>   yes filled above    1
    //    1      1      0      0   =>   yes if open         4
    //    1      1      0      1   =>   yes filled below    2
    //    1      1      1      0   =>   yes filled above    1
    //    1      1      1      1   =>   no                  0
    return selectt(
      segments,
      [
        0, 0, 0, 4,
        0, 2, 0, 2,
        0, 0, 1, 1,
        4, 2, 1, 0
      ],
      log,
    );
  }

  // prettier-ignore
  static difference(segments: SegmentBool[], log: BuildLog | undefined) {
    // primary - secondary
    // above1 below1 above2 below2    Keep?               Value
    //    0      0      0      0   =>   yes if open         4
    //    0      0      0      1   =>   no                  0
    //    0      0      1      0   =>   no                  0
    //    0      0      1      1   =>   no                  0
    //    0      1      0      0   =>   yes filled below    2
    //    0      1      0      1   =>   no                  0
    //    0      1      1      0   =>   yes filled below    2
    //    0      1      1      1   =>   no                  0
    //    1      0      0      0   =>   yes filled above    1
    //    1      0      0      1   =>   yes filled above    1
    //    1      0      1      0   =>   no                  0
    //    1      0      1      1   =>   no                  0
    //    1      1      0      0   =>   no                  0
    //    1      1      0      1   =>   yes filled above    1
    //    1      1      1      0   =>   yes filled below    2
    //    1      1      1      1   =>   no                  0
    return selectt(
      segments,
      [
        4, 0, 0, 0,
        2, 0, 2, 0,
        1, 1, 0, 0,
        0, 1, 2, 0
      ],
      log,
    );
  }

  // prettier-ignore
  static differenceRev(segments: SegmentBool[], log: BuildLog | undefined) {
    // secondary - primary
    // above1 below1 above2 below2    Keep?               Value
    //    0      0      0      0   =>   yes if open         4
    //    0      0      0      1   =>   yes filled below    2
    //    0      0      1      0   =>   yes filled above    1
    //    0      0      1      1   =>   no                  0
    //    0      1      0      0   =>   no                  0
    //    0      1      0      1   =>   no                  0
    //    0      1      1      0   =>   yes filled above    1
    //    0      1      1      1   =>   yes filled above    1
    //    1      0      0      0   =>   no                  0
    //    1      0      0      1   =>   yes filled below    2
    //    1      0      1      0   =>   no                  0
    //    1      0      1      1   =>   yes filled below    2
    //    1      1      0      0   =>   no                  0
    //    1      1      0      1   =>   no                  0
    //    1      1      1      0   =>   no                  0
    //    1      1      1      1   =>   no                  0
    return selectt(
      segments,
      [
        4, 2, 1, 0,
        0, 0, 1, 1,
        0, 2, 0, 2,
        0, 0, 0, 0
      ],
      log,
    );
  }

  // prettier-ignore
  static xor(segments: SegmentBool[], log: BuildLog | undefined) {
    // primary ^ secondary
    // above1 below1 above2 below2    Keep?               Value
    //    0      0      0      0   =>   yes if open         4
    //    0      0      0      1   =>   yes filled below    2
    //    0      0      1      0   =>   yes filled above    1
    //    0      0      1      1   =>   no                  0
    //    0      1      0      0   =>   yes filled below    2
    //    0      1      0      1   =>   no                  0
    //    0      1      1      0   =>   no                  0
    //    0      1      1      1   =>   yes filled above    1
    //    1      0      0      0   =>   yes filled above    1
    //    1      0      0      1   =>   no                  0
    //    1      0      1      0   =>   no                  0
    //    1      0      1      1   =>   yes filled below    2
    //    1      1      0      0   =>   no                  0
    //    1      1      0      1   =>   yes filled above    1
    //    1      1      1      0   =>   yes filled below    2
    //    1      1      1      1   =>   no                  0
    return selectt(
      segments,
      [
        4, 2, 1, 0,
        2, 0, 0, 1,
        1, 0, 0, 2,
        0, 1, 2, 0
      ],
      log,
    );
  }
}
