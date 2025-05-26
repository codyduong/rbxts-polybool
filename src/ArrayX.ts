//
// custom array utility functions for the roblox environment
// by Cody Duong (@codyduong), https://codyduong.dev
// todo, this should really be a seperate package
//
// Project Home: https://github.com/codyduong/rbxts-polybool
// SPDX-License-Identifier: 0BSD
//
// rbxts       version: 0.1.0     (https://github.com/codyduong/rbxts-polybool/releases/tag/v0.1.0)
// polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
//

/**
 * @param arraysOrValues Arrays or values to concatenate.
 * @returns A new array containing the concatenated elements.
 */
export function concat<T extends defined, U extends defined[]>(...arraysOrValues: (T | U)[]): (T | U[number])[] {
  const result: (T | U[number])[] = [];

  for (const arg of arraysOrValues) {
    if (ArrayX.isArray(arg)) {
      for (const item of arg) {
        result.push(item);
      }
    } else {
      result.push(arg);
    }
  }
  return result;
}

export function isArray(arg: unknown): arg is unknown[] {
  // this check is not very good -@codyduong
  return typeIs(arg, "table"); // && (arg as Record<number, unknown>)[0] !== undefined;
}

/**
 * @param arr The array to modify. This array is modified in place.
 * @param start The index at which to start changing the array.
 * @param deleteCount? The number of elements to remove.
 * @param items Elements to insert.
 * @returns An array containing the removed elements.
 */
export function splice<T extends defined>(arr: T[], start: number, deleteCount?: number, ...items: T[]): T[] {
  if (!ArrayX.isArray(arr)) {
    error("TypeError: arr must be an array");
  }

  const arrLength = arr.size();
  const removed: T[] = [];

  // Handle negative start index
  if (start < 0) {
    start = math.max(arrLength + start, 0);
  } else {
    start = math.min(start, arrLength);
  }

  // Handle deleteCount
  if (deleteCount === undefined) {
    deleteCount = arrLength - start;
  } else {
    deleteCount = math.max(0, math.min(deleteCount, arrLength - start));
  }

  // 1. Remove elements to be deleted
  for (let i = start; i < start + deleteCount; i++) {
    if (i < arrLength) {
      removed.push(arr[i]);
    }
  }

  // 2. Calculate new length and shift elements
  const itemsCount = items.size();
  const delta = itemsCount - deleteCount;

  if (delta < 0) {
    // Shift left (more deleted than inserted)
    const shiftStart = start + deleteCount;
    const shiftEnd = arrLength - 1;
    const shiftBy = -delta;

    for (let i = shiftStart; i <= shiftEnd; i++) {
      arr[i - shiftBy] = arr[i];
    }

    // Remove extra elements from end
    for (let i = arrLength - 1; i >= arrLength + delta; i--) {
      arr[i] = undefined!;
    }
  } else if (delta > 0) {
    // Shift right (more inserted than deleted)
    const shiftStart = arrLength - 1;
    const shiftEnd = start + deleteCount;

    // Make space by adding undefined elements
    for (let i = 0; i < delta; i++) {
      arr.push(undefined!);
    }

    // Shift elements right
    for (let i = shiftStart; i >= shiftEnd; i--) {
      arr[i + delta] = arr[i];
    }
  }

  // 3. Insert new items
  for (let i = 0; i < itemsCount; i++) {
    arr[start + i] = items[i];
  }

  return removed;
}

/**
 * Simulates JavaScript's Array.prototype.slice
 * @param arr The array to slice.
 * @param start The beginning index of the slice.
 * @param end_ The ending index of the slice (exclusive).
 * @returns A new array containing the extracted elements.
 */
export function slice<T extends defined>(arr: T[], start: number, end_?: number): T[] {
  // Ensure arr is an array
  if (!ArrayX.isArray(arr)) {
    error("TypeError: arr must be an array");
  }

  const arrLength = arr.size();
  let newStart = start < 0 ? math.max(arrLength + start, 0) : math.min(start, arrLength);
  let newEnd: number;

  if (end_ === undefined) {
    newEnd = arrLength;
  } else {
    newEnd = end_ < 0 ? math.max(arrLength + end_, 0) : math.min(end_, arrLength);
  }

  // Calculate the size needed for the result
  const resultSize = math.max(0, newEnd - newStart);
  const result: T[] = [];

  // Manually truncate by only pushing needed elements
  for (let i = newStart; i < newEnd; i++) {
    result.push(arr[i]);
  }

  // Ensure the size is correct by removing excess elements
  // This handles cases where newEnd was before newStart
  while (result.size() > resultSize) {
    result.pop();
  }

  return result;
}

const ArrayX = {
  isArray,
  concat,
  slice,
  splice,
};

export default ArrayX;
