//
// polybool - Boolean operations on polygons (union, intersection, etc)
// by Sean Connelly (@velipso), https://sean.fun
// adapted to roblox by Cody Duong (@codyduong), https://codyduong.dev
//
// Project Home: https://github.com/codyduong/rbxts-polybool
// SPDX-License-Identifier: 0BSD
//
// rbxts       version: 0.1.2     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.2)
// polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
//

/* eslint-disable @typescript-eslint/explicit-function-return-type */

import { type Vec2, type Vec6, type Geometry, GeometryEpsilon } from "./Geometry";
import { Shape, type ShapeCombined } from "./Shape";
import BuildLog from "./BuildLog";
export * from "./Segment";
export * from "./Geometry";
export * from "./Intersecter";
export * from "./SegmentSelector";
export * from "./SegmentChainer";
export * from "./Shape";
export * from "./BuildLog";

export interface Polygon {
  regions: Array<Array<Vec2 | Vec6>>;
  inverted: boolean;
}

export interface Segments {
  shape: Shape;
  inverted: boolean;
}

export interface CombinedSegments {
  shape: ShapeCombined;
  inverted1: boolean;
  inverted2: boolean;
}

export class PolyBool {
  private readonly geo: Geometry;
  private log: BuildLog | undefined;

  constructor(geo: Geometry = new GeometryEpsilon(), log: BuildLog | undefined = undefined) {
    this.geo = geo;
    this.log = log;
  }

  shape() {
    return new Shape(this.geo, undefined, this.log);
  }

  buildLog(enable: boolean) {
    this.log = enable ? new BuildLog() : undefined;
    return this.log?.list;
  }

  segments(poly: Polygon): Segments {
    const shape = this.shape();
    shape.beginPath();
    for (const region of poly.regions) {
      const lastPoint = region[region.size() - 1];
      shape.moveTo(lastPoint[lastPoint.size() - 2], lastPoint[lastPoint.size() - 1]);
      for (const p of region) {
        if (p.size() === 2) {
          shape.lineTo(p[0], p[1]);
        } else if (p.size() === 6) {
          shape.bezierCurveTo(p[0], p[1], p[2]!, p[3]!, p[4]!, p[5]!);
        } else {
          error("PolyBool: Invalid point in region");
        }
      }
      shape.closePath();
    }
    return { shape, inverted: poly.inverted };
  }

  combine(segments1: Segments, segments2: Segments): CombinedSegments {
    return {
      shape: segments1.shape.combine(segments2.shape),
      inverted1: segments1.inverted,
      inverted2: segments2.inverted,
    };
  }

  selectUnion(combined: CombinedSegments): Segments {
    return {
      shape: combined.inverted1
        ? combined.inverted2
          ? combined.shape.intersect()
          : combined.shape.difference()
        : combined.inverted2
          ? combined.shape.differenceRev()
          : combined.shape.union(),
      inverted: combined.inverted1 || combined.inverted2,
    };
  }

  selectIntersect(combined: CombinedSegments): Segments {
    return {
      shape: combined.inverted1
        ? combined.inverted2
          ? combined.shape.union()
          : combined.shape.differenceRev()
        : combined.inverted2
          ? combined.shape.difference()
          : combined.shape.intersect(),
      inverted: combined.inverted1 && combined.inverted2,
    };
  }

  selectDifference(combined: CombinedSegments): Segments {
    return {
      shape: combined.inverted1
        ? combined.inverted2
          ? combined.shape.differenceRev()
          : combined.shape.union()
        : combined.inverted2
          ? combined.shape.intersect()
          : combined.shape.difference(),
      inverted: combined.inverted1 && !combined.inverted2,
    };
  }

  selectDifferenceRev(combined: CombinedSegments): Segments {
    return {
      shape: combined.inverted1
        ? combined.inverted2
          ? combined.shape.difference()
          : combined.shape.intersect()
        : combined.inverted2
          ? combined.shape.union()
          : combined.shape.differenceRev(),
      inverted: !combined.inverted1 && combined.inverted2,
    };
  }

  selectXor(combined: CombinedSegments): Segments {
    return {
      shape: combined.shape.xor(),
      inverted: combined.inverted1 !== combined.inverted2,
    };
  }

  polygon(segments: Segments): Polygon {
    const regions: Array<Array<Vec2 | Vec6>> = [];
    const receiver = {
      beginPath: () => {},
      moveTo: () => {
        regions.push([]);
      },
      lineTo: (x: number, y: number) => {
        regions[regions.size() - 1].push([x, y]);
      },
      bezierCurveTo: (c1x: number, c1y: number, c2x: number, c2y: number, x: number, y: number) => {
        regions[regions.size() - 1].push([c1x, c1y, c2x, c2y, x, y]);
      },
      closePath: () => {},
    };
    segments.shape.output(receiver);
    return { regions, inverted: segments.inverted };
  }

  // helper functions for common operations
  union(poly1: Polygon, poly2: Polygon): Polygon {
    const seg1 = this.segments(poly1);
    const seg2 = this.segments(poly2);
    const comb = this.combine(seg1, seg2);
    const seg3 = this.selectUnion(comb);
    return this.polygon(seg3);
  }

  intersect(poly1: Polygon, poly2: Polygon): Polygon {
    const seg1 = this.segments(poly1);
    const seg2 = this.segments(poly2);
    const comb = this.combine(seg1, seg2);
    const seg3 = this.selectIntersect(comb);
    return this.polygon(seg3);
  }

  difference(poly1: Polygon, poly2: Polygon): Polygon {
    const seg1 = this.segments(poly1);
    const seg2 = this.segments(poly2);
    const comb = this.combine(seg1, seg2);
    const seg3 = this.selectDifference(comb);
    return this.polygon(seg3);
  }

  differenceRev(poly1: Polygon, poly2: Polygon): Polygon {
    const seg1 = this.segments(poly1);
    const seg2 = this.segments(poly2);
    const comb = this.combine(seg1, seg2);
    const seg3 = this.selectDifferenceRev(comb);
    return this.polygon(seg3);
  }

  xor(poly1: Polygon, poly2: Polygon): Polygon {
    const seg1 = this.segments(poly1);
    const seg2 = this.segments(poly2);
    const comb = this.combine(seg1, seg2);
    const seg3 = this.selectXor(comb);
    return this.polygon(seg3);
  }
}

const polybool = new PolyBool();

export default polybool;
