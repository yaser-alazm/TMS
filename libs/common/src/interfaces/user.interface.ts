export interface User {
  id: string
  username: string
  email: string
  firstName?: string
  lastName?: string
  createdAt: Date
  updatedAt: Date
  isActive: boolean
  roles: string[] // Array of role names
  permissions: string[] // Array of permission names
  lastLogin?: Date // Optional field for last login time
}
