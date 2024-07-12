'use client'
import { useState } from 'react';
import { createPublicClient, http } from 'viem'
import { mainnet } from 'viem/chains'
import OrbitABI from '../abi/orbit.json'
 
const client = createPublicClient({ 
  chain: mainnet, 
  transport: http(), 
}) 

const contractAddress = '0x0483b0dfc6c78062b9e999a82ffb795925381415'

export default function Home() {
  const [tokenId, setTokenId] = useState('');
  const [owner, setOwner] = useState('');
  const [tokenURI, setTokenURI] = useState('');

  const handleTokenIdChange = (value: string) => {
    setTokenId(value);
    setOwner('');
    setTokenURI('');
  }

  const handleQuery = () => {
    client.readContract({
      address: contractAddress,
      abi: OrbitABI,
      functionName: 'ownerOf',
      args: [BigInt(tokenId)]
    }).then((res: any) => {
      console.log(String(res));
      setOwner(String(res));
    })
    client.readContract({
      address: contractAddress,
      abi: OrbitABI,
      functionName: 'tokenURI',
      args: [BigInt(tokenId)]
    }).then((res: any) => {
      console.log(String(res));
      setTokenURI(res);
    })
  }
  
  return (
    <div className='p-4'>
      <div className='mb-4'>
        <label className="mr-4">tokenId:</label>
        <input className="shadow appearance-none border rounded w-40 py-2 px-3 mr-4 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" type="text" placeholder="Enter tokenId" value={tokenId} onChange={e => handleTokenIdChange(e.target.value)} />
        <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" onClick={handleQuery}>Query</button>
      </div>
      <div className='mb-4'>
        {
          owner ? (
            <p>
              the Owner of token#{tokenId} is <br />
              {owner}
            </p>
          ) : null
        }
      </div>
      <div className='mb-4'>
        {
          tokenURI ? (
            <p>
              the tokenURI of token#{tokenId} is <br />
              {tokenURI}
            </p>
          ) : null
        }
      </div>
    </div>
  );
}
