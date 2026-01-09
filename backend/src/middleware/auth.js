/**
 * Authentication Middleware
 */
const jwt = require('jsonwebtoken');
const { prisma } = require('../utils/database');
const { ApiError } = require('./errorHandler');

/**
 * Verify JWT token and attach user to request
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(401, 'Access token required');
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        isVerified: true
      }
    });

    if (!user) {
      throw new ApiError(401, 'User not found');
    }

    if (!user.isActive) {
      throw new ApiError(403, 'Account is deactivated');
    }

    req.user = user;
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
    } else if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      next(new ApiError(401, 'Invalid or expired token'));
    } else {
      next(error);
    }
  }
};

/**
 * Optional authentication - doesn't fail if no token
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          isActive: true
        }
      });

      if (user && user.isActive) {
        req.user = user;
      }
    }
    next();
  } catch {
    // Silently continue without auth
    next();
  }
};

/**
 * Require specific roles
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError(401, 'Authentication required'));
    }

    if (!roles.includes(req.user.role)) {
      return next(new ApiError(403, 'Insufficient permissions'));
    }

    next();
  };
};

/**
 * Require admin role
 */
const requireAdmin = requireRole('ADMIN');

/**
 * Require professor or admin role
 */
const requireProfessor = requireRole('PROFESSOR', 'ADMIN');

/**
 * Require verified email
 */
const requireVerified = (req, res, next) => {
  if (!req.user?.isVerified) {
    return next(new ApiError(403, 'Email verification required'));
  }
  next();
};

module.exports = {
  authenticate,
  optionalAuth,
  requireRole,
  requireAdmin,
  requireProfessor,
  requireVerified
};
