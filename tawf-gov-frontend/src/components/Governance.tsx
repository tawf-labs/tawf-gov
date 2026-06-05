import { motion } from 'framer-motion'
import { Vote, FileText, Clock, CheckCircle } from 'lucide-react'
import { useWallet } from '@solana/wallet-adapter-react'
import { WalletMultiButton } from '@solana/wallet-adapter-react-ui'

export default function Governance() {
  const { publicKey } = useWallet()

  const proposals = [
    { id: 1, title: 'Mosque Renovation Fund', status: 'Voting', votes: { for: 80, against: 10 }, deadline: '2d left' },
    { id: 2, title: 'Community Water Well', status: 'Completed', votes: { for: 120, against: 5 }, deadline: 'Passed' },
    { id: 3, title: 'Education Scholarship', status: 'Draft', votes: { for: 0, against: 0 }, deadline: '—' },
  ]

  return (
    <section id="governance" className="py-16 bg-tawf-sand">
      <div className="container mx-auto px-4">
        <motion.h2
          className="font-heading text-3xl md:text-4xl text-tawf-green mb-8 text-center"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          Governance
        </motion.h2>

        {!publicKey ? (
          <div className="text-center">
            <p className="text-tawf-muted mb-4">Connect wallet to participate in governance</p>
            <WalletMultiButton className="!bg-tawf-green !rounded-full" />
          </div>
        ) : (
          <div className="grid gap-6 max-w-3xl mx-auto">
            {proposals.map((p, i) => (
              <motion.div
                key={p.id}
                className="card flex items-start gap-4"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
              >
                <div className="p-2 rounded-lg bg-tawf-sand-dark">
                  {p.status === 'Voting' ? <Vote className="w-6 h-6 text-tawf-gold" />
                    : p.status === 'Completed' ? <CheckCircle className="w-6 h-6 text-tawf-green" />
                    : <FileText className="w-6 h-6 text-tawf-muted" />}
                </div>
                <div className="flex-1">
                  <h3 className="font-heading text-lg text-tawf-green">{p.title}</h3>
                  <div className="flex gap-4 mt-2 text-sm text-tawf-muted">
                    <span className="flex items-center gap-1"><span className={`w-2 h-2 rounded-full ${p.status === 'Voting' ? 'bg-tawf-gold' : p.status === 'Completed' ? 'bg-tawf-green' : 'bg-tawf-muted'}`} />{p.status}</span>
                    <span className="flex items-center gap-1"><Clock size={14} />{p.deadline}</span>
                    <span>{p.votes.for}F / {p.votes.against}A</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </section>
  )
}