# Frontend Modular Architecture (`src/`)

- `src/components/` — `Navbar.jsx`, `Footer.jsx`, `ProductCard.jsx`, `ProductGrid.jsx`, `SearchBar.jsx`, `CategoryFilter.jsx`, `PriceFilter.jsx`, `Pagination.jsx`, `LoginForm.jsx`, `RegisterForm.jsx`, `CartDrawer.jsx`, `Checkout.jsx`, `AdminSidebar.jsx`, `DashboardStats.jsx`, `FileUpload.jsx`
- `src/pages/` — `HomePage.jsx`, `MarketplacePage.jsx`, `ProductDetailsPage.jsx`, `CustomerDashboardPage.jsx`, `AdminDashboardPage.jsx`, `ContactSupportPage.jsx`
- `src/layouts/` — `StorefrontLayout.jsx`, `DashboardLayout.jsx`
- `src/services/` — `api.js` (Axios instance + ProductService, CheckoutService, CustomerVaultService, AdminVaultService)
- `src/context/` — `AuthContext.jsx`, `CartContext.jsx`, `BrandLocaleContext.jsx`
- `src/hooks/` — `useDebounce.js`, `useSignedDownload.js`
- `src/utils/` — `currency.js`, `razorpayLoader.js`
- `src/App.jsx` & `src/main.jsx` — Root application and router entry point (also bundled in `DigitalVault.tsx` for instant interactive preview).
