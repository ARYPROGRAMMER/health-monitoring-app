export const sendSuccess = (response, data, message = 'Request completed') => {
  response.json({
    success: true,
    message,
    data
  });
};
