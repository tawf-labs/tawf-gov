import { motion } from 'framer-motion'
import { ArrowRight } from 'lucide-react'
import { useWallet } from '@solana/wallet-adapter-react'
import { WalletMultiButton } from '@solana/wallet-adapter-react-ui'

export default function Donate() {
  const { publicKey } = useWallet()

  return (
    <section id="donate" className="py-16 bg-tawf-green text-white">
      <div className="container mx-auto px-4 text-center">
        <motion.h2
          className="font-heading text-3xl md:text-4xl mb-4"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          Make a Contribution
        </motion.h2>
        <motion.p
          className="text-lg opacity-90 mb-8 max-w-xl mx-auto"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.15 }}
        >
          Your Zakat, Wakaf, or Sadaqah donations are verified on-chain
          — transparent and Sharia-compliant.
        </motion.p>
        <motion.div
          className="flex flex-col items-center gap-4"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.3 }}
        >
          {!publicKey ? (
            <WalletMultiButton className="!bg-tawf-gold !text-tawf-ink !rounded-full !px-8 !py-4 !font-semibold" />
          ) : (
            <div className="space-y-4">
              <p className="text-sm opacity-75">Connected: {publicKey.toBase58().slice(0, 8)}...</p>
              <div className="flex gap-4 justify-center">
                <a href="#pools" className="btn-pill bg-tawf-gold text-tawf-ink flex items-center gap-2">
                  View Campaigns <ArrowRight size={16} />
                </a>
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </section>
  )
}