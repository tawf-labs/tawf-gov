import { useMemo } from 'react'
import { ConnectionProvider, WalletProvider } from '@solana/wallet-adapter-react'
import { UnsafeBurnerWalletAdapter } from '@solana/wallet-adapter-wallets'
import { WalletModalProvider } from '@solana/wallet-adapter-react-ui'
import Layout from './components/Layout'
import Landing from './components/Landing'
import Manifesto from './components/Manifesto'
import Donate from './components/Donate'
import Governance from './components/Governance'
import './index.css'
import '@solana/wallet-adapter-react-ui/styles.css'

const endpoint = 'http://localhost:8899'

export default function App() {
  const wallets = useMemo(() => [new UnsafeBurnerWalletAdapter()], [])

  return (
    <ConnectionProvider endpoint={endpoint}>
      <WalletProvider wallets={wallets} autoConnect>
        <WalletModalProvider>
          <Layout>
            <Landing />
            <Manifesto />
            <Donate />
            <Governance />
          </Layout>
        </WalletModalProvider>
      </WalletProvider>
    </ConnectionProvider>
  )
}