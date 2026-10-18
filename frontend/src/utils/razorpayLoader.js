/**
 * Dynamically loads the official Razorpay Checkout SDK (https://checkout.razorpay.com/v1/checkout.js)
 * and opens the payment modal using the server-created razorpay_order_id.
 */
export function loadRazorpayScript() {
  return new Promise((resolve) => {
    if (window.Razorpay) {
      resolve(true);
      return;
    }
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
}

export async function openRazorpayCheckout({
  razorpayOrderId,
  amountInPaise,
  customerName,
  customerEmail,
  customerPhone,
  brandName = 'DigitalVault',
  onSuccessVerify,
  onFailure,
}) {
  const loaded = await loadRazorpayScript();
  if (!loaded) {
    throw new Error('Razorpay Checkout SDK failed to load. Check your network connection.');
  }

  const options = {
    key: import.meta.env.VITE_RAZORPAY_PUBLIC_KEY_ID, // Public key_id only; NEVER key_secret
    amount: amountInPaise,
    currency: 'INR',
    name: brandName,
    description: 'Authorized Digital Resource Purchase',
    order_id: razorpayOrderId,
    prefill: {
      name: customerName,
      email: customerEmail,
      contact: customerPhone,
    },
    theme: {
      color: '#2563EB',
    },
    handler: async function (response) {
      // Forward razorpay_order_id, razorpay_payment_id, and razorpay_signature to backend for HMAC-SHA256 verification
      await onSuccessVerify({
        razorpayOrderId: response.razorpay_order_id,
        razorpayPaymentId: response.razorpay_payment_id,
        razorpaySignature: response.razorpay_signature,
      });
    },
  };

  const rzp = new window.Razorpay(options);
  rzp.on('payment.failed', function (response) {
    if (onFailure) onFailure(response.error);
  });
  rzp.open();
}
