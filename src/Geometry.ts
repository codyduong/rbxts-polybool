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

/**
 * This is a utility type used by polybool, in order to get an alternative representation
 * or the roblox equivalent Vector2 class, then you will want to use `intoVector2`
 *
 * @example
 * ```
 * import { intoVector2, Vec2 } from "@rbxts/polybool";
 *
 * const vec2: Vec2 = [0.5, 0.5];
 * const vector2 = intoVector2(vec2);
 * ```
 */
export type Vec2 = [x: number, y: number];
export type Vec6 = [number, number, number, number, number, number];

export function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t;
}

export function lerpVec2(a: Vec2, b: Vec2, t: number): Vec2 {
  return [lerp(a[0], b[0], t), lerp(a[1], b[1], t)];
}

export function boundingBoxesIntersect(bbox1: [Vec2, Vec2], bbox2: [Vec2, Vec2]) {
  const [b1min, b1max] = bbox1;
  const [b2min, b2max] = bbox2;
  return !(b1min[0] > b2max[0] || b1max[0] < b2min[0] || b1min[1] > b2max[1] || b1max[1] < b2min[1]);
}

export abstract class Geometry {
  abstract snap0(v: number): number;
  abstract snap01(v: number): number;
  abstract isCollinear(p1: Vec2, p2: Vec2, p3: Vec2): boolean;
  abstract solveCubic(a: number, b: number, c: number, d: number): number[];
  abstract isEqualVec2(a: Vec2, b: Vec2): boolean;
  abstract compareVec2(a: Vec2, b: Vec2): number;
}

export class GeometryEpsilon extends Geometry {
  readonly epsilon: number;

  constructor(epsilon = 0.0000000001) {
    super();
    this.epsilon = epsilon;
  }

  snap0(v: number) {
    if (math.abs(v) < this.epsilon) {
      return 0;
    }
    return v;
  }

  snap01(v: number) {
    if (math.abs(v) < this.epsilon) {
      return 0;
    }
    if (math.abs(1 - v) < this.epsilon) {
      return 1;
    }
    return v;
  }

  isCollinear(p1: Vec2, p2: Vec2, p3: Vec2) {
    // does pt1->pt2->pt3 make a straight line?
    // essentially this is just checking to see if
    //   slope(pt1->pt2) === slope(pt2->pt3)
    // if slopes are equal, then they must be collinear, because they share pt2
    const dx1 = p1[0] - p2[0];
    const dy1 = p1[1] - p2[1];
    const dx2 = p2[0] - p3[0];
    const dy2 = p2[1] - p3[1];
    return math.abs(dx1 * dy2 - dx2 * dy1) < this.epsilon;
  }

  private solveCubicNormalized(a: number, b: number, c: number) {
    // based somewhat on gsl_poly_solve_cubic from GNU Scientific Library
    const a3 = a / 3;
    const b3 = b / 3;
    const Q = a3 * a3 - b3;
    const R = a3 * (a3 * a3 - b / 2) + c / 2;
    if (math.abs(R) < this.epsilon && math.abs(Q) < this.epsilon) {
      return [-a3];
    }
    const F = a3 * (a3 * (4 * a3 * c - b3 * b) - 2 * b * c) + 4 * b3 * b3 * b3 + c * c;
    if (math.abs(F) < this.epsilon) {
      const sqrtQ = math.sqrt(Q);
      return R > 0 ? [-2 * sqrtQ - a / 3, sqrtQ - a / 3] : [-sqrtQ - a / 3, 2 * sqrtQ - a / 3];
    }
    const Q3 = Q * Q * Q;
    const R2 = R * R;
    if (R2 < Q3) {
      const ratio = (R < 0 ? -1 : 1) * math.sqrt(R2 / Q3);
      const theta = math.acos(ratio);
      const norm = -2 * math.sqrt(Q);
      const x0 = norm * math.cos(theta / 3) - a3;
      const x1 = norm * math.cos((theta + 2 * math.pi) / 3) - a3;
      const x2 = norm * math.cos((theta - 2 * math.pi) / 3) - a3;
      return [x0, x1, x2].sort((x, y) => x <= y);
    } else {
      const A = (R < 0 ? 1 : -1) * math.pow(math.abs(R) + math.sqrt(R2 - Q3), 1 / 3);
      const B = math.abs(A) >= this.epsilon ? Q / A : 0;
      return [A + B - a3];
    }
  }

  solveCubic(a: number, b: number, c: number, d: number) {
    if (math.abs(a) < this.epsilon) {
      // quadratic
      if (math.abs(b) < this.epsilon) {
        // linear case
        if (math.abs(c) < this.epsilon) {
          // horizontal line
          return math.abs(d) < this.epsilon ? [0] : [];
        }
        return [-d / c];
      }
      const b2 = 2 * b;
      let D = c * c - 4 * b * d;
      if (math.abs(D) < this.epsilon) {
        return [-c / b2];
      } else if (D > 0) {
        D = math.sqrt(D);
        return [(-c + D) / b2, (-c - D) / b2].sort((x, y) => x <= y);
      }
      return [];
    }
    return this.solveCubicNormalized(b / a, c / a, d / a);
  }

  isEqualVec2(a: Vec2, b: Vec2) {
    return math.abs(a[0] - b[0]) < this.epsilon && math.abs(a[1] - b[1]) < this.epsilon;
  }

  compareVec2(a: Vec2, b: Vec2) {
    // returns -1 if a is smaller, 1 if b is smaller, 0 if equal
    if (math.abs(b[0] - a[0]) < this.epsilon) {
      return math.abs(b[1] - a[1]) < this.epsilon ? 0 : a[1] < b[1] ? -1 : 1;
    }
    return a[0] < b[0] ? -1 : 1;
  }
}

// checks if something is array by simply checking if it has a size
const quickarray = (u: unknown): u is unknown[] => {
  return typeIs(u, "table") && typeIs((u as unknown[]).size(), "number");
};

export function isVector2(u: unknown): u is Vector2 {
  return typeIs(u, "Vector2");
}

export function isVec2(u: unknown): u is Vec2 {
  return quickarray(u) && u.size() === 2 && typeIs(u[0], "number") && typeIs(u[1], "number");
}

export function isVec6(u: unknown): u is Vec2 {
  return (
    quickarray(u) &&
    u.size() === 6 &&
    typeIs(u[0], "number") &&
    typeIs(u[1], "number") &&
    typeIs(u[2], "number") &&
    typeIs(u[3], "number") &&
    typeIs(u[4], "number") &&
    typeIs(u[5], "number")
  );
}

export function intoVec2(vector2: Vector2): Vec2;
export function intoVec2(vector2: unknown): Vec2 {
  assert(isVector2(vector2));
  return [vector2.X, vector2.Y];
}

export function intoVector2(vec2: Vec2): Vector2;
export function intoVector2(vec2: Vec6): Vector2;
export function intoVector2(vec2: Vec2 | Vec6): Vector2;
export function intoVector2(u: unknown): Vector2 {
  assert(isVec2(u) || isVec6(u));

  if (isVec2(u)) {
    return new Vector2(u[0], u[1]);
  }
  print(debug.traceback("Polybool: coerced Vec6 as Vec2 in order to convert it to Vec2"));

  return new Vector2(u[0], u[1]);
}
