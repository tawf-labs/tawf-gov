import { motion } from 'framer-motion'
import { ShieldCheck, Globe, Users } from 'lucide-react'

export default function Landing() {
  const stats = [
    { label: 'Total Zakat Collected', value: 'IDR 0', change: '+0%' },
    { label: 'Active Donors', value: '0', change: '+0' },
    { label: 'Recipients Served', value: '0', change: '+0' },
    { label: 'Programs Funded', value: '0', change: '+0' },
  ]

  return (
    <div>
      <section className="relative min-h-[80vh] flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-tawf-green via-tawf-green-light to-tawf-gold opacity-90" />
        <div className="relative container mx-auto px-4 text-center text-white">
          <motion.h1
            className="text-4xl md:text-6xl font-heading font-bold mb-6"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            Decentralized Sharia-Compliant<br className="hidden md:block" />Zakat & Wakaf on Solana
          </motion.h1>
          <motion.p
            className="text-lg md:text-xl max-w-2xl mx-auto mb-8 opacity-90"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            Transparent, verifiable, and automated Islamic charitable giving
            powered by blockchain technology.
          </motion.p>
          <motion.div
            className="flex flex-col sm:flex-row gap-4 justify-center"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            <a href="/donate" className="btn-pill bg-white text-tawf-green hover:shadow-xl">
              Donate Now
            </a>
            <a href="#manifesto" className="btn-outline border-white text-white hover:bg-white hover:text-tawf-green">
              Read Manifesto
            </a>
          </motion.div>
        </div>
      </section>

      <section className="py-16 bg-tawf-sand-dark">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {stats.map((stat, i) => (
              <motion.div
                key={stat.label}
                className="card text-center"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: i * 0.1 }}
              >
                <p className="text-2xl md:text-3xl font-bold text-tawf-green">
                  {stat.value}
                </p>
                <p className="text-sm text-tawf-muted mt-1">{stat.label}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-16 container mx-auto px-4">
        <div className="grid md:grid-cols-3 gap-8">
          {[
            {
              icon: ShieldCheck,
              title: 'Verifiable on Chain',
              desc: 'Every transaction is recorded immutably on Solana.',
            },
            {
              icon: Globe,
              title: 'Indonesia-Focused',
              desc: 'Built for Indonesian Muslims by the Tawf community.',
            },
            {
              icon: Users,
              title: 'Community Governance',
              desc: 'Donors and recipients participate in decisions.',
            },
          ].map((feature, i) => (
            <motion.div
              key={feature.title}
              className="card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: i * 0.15 }}
            >
              <feature.icon className="w-12 h-12 text-tawf-gold mb-4" />
              <h3 className="font-heading text-xl text-tawf-green mb-2">
                {feature.title}
              </h3>
              <p className="text-tawf-muted">{feature.desc}</p>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  )
}