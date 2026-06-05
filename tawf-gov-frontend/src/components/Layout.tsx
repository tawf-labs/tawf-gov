import React from 'react'
import { motion } from 'framer-motion'
import { Menu, X } from 'lucide-react'
import { useState } from 'react'
import { WalletMultiButton } from '@solana/wallet-adapter-react-ui'

export default function Layout({ children }: { children: React.ReactNode }) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  const navItems = [
    { label: 'Manifesto', href: '#manifesto' },
    { label: 'Programs', href: '#programs' },
    { label: 'Governance', href: '#governance' },
    { label: 'Docs', href: '#docs' },
  ]

  return (
    <div className="min-h-screen flex flex-col">
      <header className="sticky top-0 z-50 bg-tawf-sand/80 backdrop-blur-sm border-b border-tawf-border">
        <div className="container mx-auto px-4 py-3 flex items-center justify-between">
          <a href="/" className="font-heading text-2xl font-bold text-tawf-green">
            Tawf
          </a>

          <nav className="hidden md:flex items-center space-x-8">
            {navItems.map(item => (
              <a
                key={item.label}
                href={item.href}
                className="text-tawf-ink hover:text-tawf-green transition-colors font-medium"
              >
                {item.label}
              </a>
            ))}
            <WalletMultiButton className="!bg-tawf-green !rounded-full !px-4 !py-2 !text-sm" />
          </nav>

          <button
            className="md:hidden p-2 text-tawf-ink"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {mobileMenuOpen && (
          <motion.nav
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="md:hidden bg-tawf-sand border-b border-tawf-border"
          >
            <div className="container mx-auto px-4 py-2 space-y-2">
              {navItems.map(item => (
                <a
                  key={item.label}
                  href={item.href}
                  className="block py-2 text-tawf-ink hover:text-tawf-green transition-colors"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {item.label}
                </a>
              ))}
            </div>
          </motion.nav>
        )}
      </header>

      <main className="flex-1">{children}</main>

      <footer className="bg-tawf-green text-white py-8 mt-16">
        <div className="container mx-auto px-4 text-center">
          <p className="text-sm">
            © {new Date().getFullYear()} Tawf Foundation. Built on Solana.
          </p>
        </div>
</footer>
     </div>
   )
}