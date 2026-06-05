import { motion } from 'framer-motion'

export default function Manifesto() {
  const principles = [
    {
      title: 'Halal Finance',
      desc: 'All operations comply with Syariah principles - no interest, no speculation, no gambling.',
    },
    {
      title: 'Transparency',
      desc: 'Every contribution and distribution is recorded on-chain for public verification.',
    },
    {
      title: 'Community First',
      desc: 'Governance is decentralized - donors and recipients have voice and vote.',
    },
    {
      title: 'Technology for Good',
      desc: 'We leverage modern technology to maximize impact and minimize administrative overhead.',
    },
  ]

  return (
    <div className="py-16">
      <section className="container mx-auto px-4 text-center mb-16">
        <motion.h1
          className="text-4xl md:text-5xl font-heading text-tawf-green mb-6"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          Our Manifesto
        </motion.h1>
        <motion.p
          className="text-xl text-tawf-muted max-w-2xl mx-auto"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          Tawf Foundation exists to make Zakat and Wakaf more accessible,
          transparent, and impactful for every Indonesian Muslim.
        </motion.p>
      </section>

      <section className="container mx-auto px-4">
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {principles.map((p, i) => (
            <motion.div
              key={p.title}
              className="card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.15 }}
            >
              <h3 className="font-heading text-xl text-tawf-green mb-2">
                {p.title}
              </h3>
              <p className="text-tawf-muted">{p.desc}</p>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  )
}