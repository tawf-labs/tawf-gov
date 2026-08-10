import { motion } from 'framer-motion'

/// The Islamic-finance vocabulary this site uses, defined in plain English.
///
/// Scoped to the words that actually appear here. The Foundation keeps the full dictionary, and a
/// partial copy that drifts would be worse than a short list that stays correct.
const terms = [
  {
    term: 'Zakat',
    pronunciation: 'zah-kat',
    definition:
      'One of the five pillars of Islam. An obligatory annual contribution, normally 2.5% of qualifying wealth, paid by those who hold above a set threshold and given to those who fall below it.',
    here: 'The pools distribute it to eligible recipients, with every transfer recorded on-chain.',
  },
  {
    term: 'Wakaf',
    pronunciation: 'wah-kaf',
    definition:
      'An Islamic endowment. Capital is dedicated to a charitable purpose and preserved rather than spent, so that only the benefit it produces is given away. Also written waqf.',
    here: 'The treasury holds wakaf assets and allocates what they earn, never the capital itself.',
  },
  {
    term: 'Sadaqah',
    pronunciation: 'sah-dah-kah',
    definition:
      'Voluntary charity, given freely at any time and in any amount. Unlike zakat it carries no obligation, no threshold and no fixed rate.',
    here: 'Donations outside the zakat pools are sadaqah.',
  },
  {
    term: 'Syariah',
    pronunciation: 'sha-ree-ah',
    definition:
      'Islamic law, derived from the Qur’an and the Sunnah. In finance it governs what a contract may contain, prohibiting interest, excessive uncertainty and gambling. Also written Sharia.',
    here: 'Why returns come from a share in real assets rather than from lending at a rate.',
  },
  {
    term: 'Halal',
    pronunciation: 'hah-lal',
    definition:
      'Permitted under Islamic law. Applied to finance it describes an instrument whose structure, underlying assets and source of return are all permissible.',
    here: 'The standard every instrument in this system is meant to meet.',
  },
]

export default function Glossary() {
  return (
    <div id="glossary" className="py-16 scroll-mt-20">
      <section className="container mx-auto px-4 text-center mb-12">
        <motion.h2
          className="text-4xl md:text-5xl font-heading text-tawf-green mb-6"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          Glossary
        </motion.h2>
        <motion.p
          className="text-xl text-tawf-muted max-w-2xl mx-auto"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.15 }}
        >
          The Arabic terms on this site are kept rather than translated away, because the
          approximations lose the distinctions that matter. Here is what each one means.
        </motion.p>
      </section>

      <section className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
          {terms.map((t, idx) => (
            <motion.div
              key={t.term}
              className="bg-white border border-tawf-border rounded-2xl p-6"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: idx * 0.08 }}
            >
              <div className="flex flex-wrap items-baseline gap-x-3 mb-3">
                <h3 className="text-2xl font-heading text-tawf-green">{t.term}</h3>
                <span className="text-sm italic text-tawf-gold">/{t.pronunciation}/</span>
              </div>
              <p className="text-tawf-muted leading-relaxed">{t.definition}</p>
              <p className="mt-4 text-sm text-tawf-muted bg-tawf-sand/60 rounded-xl p-4">
                <span className="font-medium text-tawf-green">Here: </span>
                {t.here}
              </p>
            </motion.div>
          ))}
        </div>

        <p className="text-center text-tawf-muted mt-10">
          The full dictionary, including asnaf, nisab, amil and qardhul hasan, lives at{' '}
          <a
            href="https://tawf.foundation/glossary"
            target="_blank"
            rel="noopener noreferrer"
            className="text-tawf-green underline underline-offset-4 hover:text-tawf-gold transition-colors"
          >
            tawf.foundation/glossary
          </a>
          .
        </p>
      </section>
    </div>
  )
}
