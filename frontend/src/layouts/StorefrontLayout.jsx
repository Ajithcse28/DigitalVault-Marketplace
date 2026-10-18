import React from 'react';

export default function StorefrontLayout({ navbar, footer, children }) {
  return (
    <div className="min-h-screen flex flex-col bg-slate-950 text-slate-100">
      {navbar}
      <main className="flex-1">{children}</main>
      {footer}
    </div>
  );
}
