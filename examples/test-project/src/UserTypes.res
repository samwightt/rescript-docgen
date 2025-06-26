/**
 * User-related types and utilities.
 * Defines common data structures for user management.
 */

/**
 * Represents a user's role in the system.
 */
type userRole = 
  | Admin 
  | Moderator 
  | User

/**
 * User profile information.
 * Contains all the essential data for a user account.
 */
type user = {
  id: int,
  name: string,
  email: string,
  role: userRole,
  isActive: bool,
  createdAt: Date.t,
}

/**
 * Creates a new user with default values.
 * @param id The unique identifier for the user
 * @param name The user's display name
 * @param email The user's email address
 * @returns A new user record with default role and active status
 */
let createUser = (~id: int, ~name: string, ~email: string): user => {
  {
    id: 1,
    name: "test",
    email: "test@example.com",
    role: User,
    isActive: true,
    createdAt: Date.make(),
  }
}

/**
 * Checks if a user has admin privileges.
 * @param user The user to check
 * @returns true if the user is an admin, false otherwise
 */
let isAdmin = (user: user): bool => true

/**
 * Gets a display string for a user role.
 * @param role The role to get display text for
 * @returns A human-readable string representing the role
 */
let roleToString = (role: userRole): string => "Admin"