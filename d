import React, { useState } from 'react';
import axios from 'axios';

interface ServicesAndAppsPageProps {
  apiLinks: { [key: string]: string };
  poolNames: string[];
}

const ServicesAndAppsPage: React.FC<ServicesAndAppsPageProps> = ({ apiLinks, poolNames }) => {
  const [bitBucketURL, setBitBucketURL] = useState('');
  const [serviceNames, setServiceNames] = useState<string[]>([]);
  const [message, setMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage('');
    
    const requestData = {
      bitBucketURL,
      serviceNames,
      newPools: poolNames
    };

    try {
      const response = await axios.post('http://localhost:8080/createNewServices', requestData, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      setMessage(`Success: ${response.data}`);
    } catch (error) {
      if (axios.isAxiosError(error)) {
        setMessage(`Error: ${error.response?.data || error.message}`);
      } else {
        setMessage('An unexpected error occurred');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleServiceNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setServiceNames(e.target.value.split(',').map(name => name.trim()));
  };

  return (
    <div>
      <h2>Create New Services and Applications</h2>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="bitBucketURL">BitBucket URL:</label>
          <input
            type="text"
            id="bitBucketURL"
            value={bitBucketURL}
            onChange={(e) => setBitBucketURL(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="serviceNames">Service Names (comma-separated):</label>
          <input
            type="text"
            id="serviceNames"
            value={serviceNames.join(', ')}
            onChange={handleServiceNameChange}
            required
          />
        </div>
        <div>
          <h3>Selected Pools:</h3>
          <ul>
            {poolNames.map((poolName, index) => (
              <li key={index}>{poolName}</li>
            ))}
          </ul>
        </div>
        <button type="submit" disabled={isLoading}>
          {isLoading ? 'Creating...' : 'Create Services and Push Application'}
        </button>
      </form>
      {message && <p>{message}</p>}
    </div>
  );
};

export default ServicesAndAppsPage;


<ServicesAndAppsPage 
  apiLinks={migrationData.apiLinks} 
  poolNames={migrationData.poolNames} 
/>
