import axios from 'axios';

/**
 * Axios API service configured with base URL from environment variables
 * and automatic JWT Bearer token attachment.
 * Never stores Razorpay key_secret or private storage keys on the client.
 */
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  try {
    const token = localStorage.getItem('dv_jwt_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  } catch {
    // Ignore storage access errors in restricted environments
  }
  return config;
});

export const ProductService = {
  listProducts: (params) => api.get('/products', { params }),
  getProductById: (id) => api.get(`/products/${id}`),
  listCategories: () => api.get('/categories'),
};

export const CheckoutService = {
  createPendingOrder: (payload) => api.post('/orders', payload),
  createRazorpayOrder: (orderId) => api.post('/payments/create', { orderId }),
  verifyRazorpayPayment: (verificationPayload) => api.post('/payments/verify', verificationPayload),
};

export const CustomerVaultService = {
  getLibrary: () => api.get('/customer/library'),
  getOrders: () => api.get('/customer/orders'),
  getSignedDownloadUrl: (assetId, userId) =>
    api.get(`/customer/downloads/${assetId}/signed-url`, { params: { userId } }),
};

export const AdminVaultService = {
  getDashboardStats: () => api.get('/admin/dashboard'),
  createProduct: (data) => api.post('/admin/products', data),
  updateProduct: (id, data) => api.put(`/admin/products/${id}`, data),
  deleteProduct: (id) => api.delete(`/admin/products/${id}`),
  uploadProductAsset: (id, formData) =>
    api.post(`/admin/products/${id}/assets`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
};

export default api;
