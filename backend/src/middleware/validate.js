/**
 * Request validation middleware using express-validator
 */
const { validationResult } = require('express-validator');
const { ApiError } = require('./errorHandler');

/**
 * Validate request and return errors
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const errorMessages = errors.array().map(err => ({
      field: err.path,
      message: err.msg
    }));

    throw new ApiError(400, 'Validation failed', errorMessages);
  }

  next();
};

module.exports = { validate };
