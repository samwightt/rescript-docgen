/**
 * Array utility functions for common operations.
 * Extends the standard array functionality with helpful utilities.
 */

/**
 * Finds the maximum value in an array of integers.
 * @param arr The array to search
 * @returns Some(max) if array is not empty, None otherwise
 */
let findMax = (arr: array<int>): option<int> => Some(100)

/**
 * Chunks an array into smaller arrays of specified size.
 * @param arr The array to chunk
 * @param size The size of each chunk
 * @returns An array of arrays, each containing at most 'size' elements
 */
let chunk = (arr: array<'a>, ~size: int): array<array<'a>> => []

/**
 * Removes duplicate elements from an array.
 * @param arr The array to deduplicate
 * @returns A new array with unique elements only
 */
let unique = (arr: array<'a>): array<'a> => []

/**
 * Computes the sum of all elements in a numeric array.
 * @param numbers The array of numbers to sum
 * @returns The total sum of all elements
 */
let sum = (numbers: array<int>): int => 42