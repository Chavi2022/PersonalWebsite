interface PoolTableProps {}

const formatNextRepave = (nextRepave: string): string => {
    if (!nextRepave) return 'N/A';
    return nextRepave.substring(0, 10);
};

const PoolTable: React.FC<PoolTableProps> = () => {
    const { user, pass, app, spaceName, orgName, oldPools, newPools } = useMigrationContext();
    const { apiLinks, setApiLinks } = useApiContext();

    const [pools, setPools] = useState<Pool[]>([]);
    const [selectedPools, setSelectedPools] = useState<Pool[]>([]);
    const [sortKey, setSortKey] = useState<string>('avgCpu');
    const [sortDesc, setSortDesc] = useState<boolean>(true);
    const [isLoading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);
    const [showDialog, setShowDialog] = useState<boolean>(false);
    const [showMigrate, setShowMigrate] = useState<boolean>(false);
    const [migrationData, setMigrationData] = useState<{ apiLinks: { [key: string]: string }, poolNames: string[] }>({ apiLinks: {}, poolNames: [] });

    useEffect(() => {
        setLoading(true);
        getFilteredPoolInfo()
            .then((response) => {
                const data: Pool[] = response.data;
                setPools(data);
                setLoading(false);

                const links = data.reduce((acc: { [key: string]: string }, pool: Pool) => {
                    acc[pool.pool] = pool.instances[0].api;
                    return acc;
                }, {});
                setApiLinks(links);
            })
            .catch((err) => {
                console.error(err);
                setError('Failed to fetch pool data');
                setLoading(false);
            });
    }, [setApiLinks]);

    const sortByAvgCpu = () => {
        const desc: boolean = sortKey === 'avgCpu' ? !sortDesc : true;
        const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
            return desc ? b.avgCpu - a.avgCpu : a.avgCpu - b.avgCpu;
        });
        setPools(sortedPools);
        setSortKey('avgCpu');
        setSortDesc(desc);
    };

    const sortByPool = () => {
        const desc: boolean = sortKey === 'pool' ? !sortDesc : true;
        const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
            const aValue: string = a.pool;
            const bValue: string = b.pool;
            return desc ? bValue.localeCompare(aValue) : aValue.localeCompare(bValue);
        });
        setPools(sortedPools);
        setSortKey('pool');
        setSortDesc(desc);
    };

    const sortByRegion = () => {
        const desc: boolean = sortKey === 'region' ? !sortDesc : true;
        const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
            const aValue: string = a.region;
            const bValue: string = b.region;
            return desc ? bValue.localeCompare(aValue) : aValue.localeCompare(bValue);
        });
        setPools(sortedPools);
        setSortKey('region');
        setSortDesc(desc);
    };

    const sortByMaxSlice = () => {
        const desc: boolean = sortKey === 'maxSlice' ? !sortDesc : true;
        const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
            const aValue: number = a.instances[0]?.capacity.maxSlice ?? 0;
            const bValue: number = b.instances[0]?.capacity.maxSlice ?? 0;
            return desc ? bValue - aValue : aValue - bValue;
        });
        setPools(sortedPools);
        setSortKey('maxSlice');
        setSortDesc(desc);
    };

    const sortByAvailability = () => {
    const desc: boolean = sortKey === "availability" ? !sortDesc : true;
    const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
        const aInstance = a.instances[0];
        const bInstance = b.instances[0];

        const aAvailability = aInstance && aInstance.capacity.total !== 0
            ? ((aInstance.capacity.total - aInstance.capacity.available) / aInstance.capacity.total) * 100
            : 0;

        const bAvailability = bInstance && bInstance.capacity.total !== 0
            ? ((bInstance.capacity.total - bInstance.capacity.available) / bInstance.capacity.total) * 100
            : 0;

        return desc ? bAvailability - aAvailability : aAvailability - bAvailability;
    });
    setPools(sortedPools);
    setSortKey("availability");
    setSortDesc(desc);
};


    const sortByNextRepave = () => {
        const desc: boolean = sortKey === 'nextRepave' ? !sortDesc : true;
        const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
            const aValue: string = a.instances[0]?.nextRepave ?? '';
            const bValue: string = b.instances[0]?.nextRepave ?? '';
            return desc ? bValue.localeCompare(aValue) : aValue.localeCompare(bValue);
        });
        setPools(sortedPools);
        setSortKey('nextRepave');
        setSortDesc(desc);
    };

    const togglePoolSelection = (pool: Pool) => {
        setSelectedPools((prev: Pool[]) => 
            prev.includes(pool) ? prev.filter(p => p !== pool) : [...prev, pool]
        );
    };

    const getAvailabilityPercentage = (available: number, total: number): number => {
        if (total === 0) return 0;
        return Math.round(((total - available) / total) * 100);
    };

    const handleContinue = () => {
        setShowDialog(false);
        setShowMigrate(true);
    };

    const handleMigrate = () => {
        console.log('Selected Pools Migration', selectedPools);
        const selectedApiLinks = selectedPools.reduce((acc, pool) => {
            acc[pool.pool] = apiLinks[pool.pool];
            return acc;
        }, {} as { [key: string]: string });
        const poolNames = selectedPools.map(pool => pool.pool);
        setMigrationData({
            apiLinks: selectedApiLinks,
            poolNames: poolNames
        });
        setShowMigrate(true);
    };

    if (isLoading) return <div>Loading...</div>;
    if (error) return <div>{error}</div>;

    return (
        <div className={tableStyles.container}>
            <Entries />
            <h1>Strategic Migration Pools</h1>
            <h6 color='green'>Choose Pools to Migrate To</h6>
            <table className={tableStyles.table}>
                <thead>
                    <tr>
                        <th className={tableStyles.th}><button onClick={sortByRegion} className={tableStyles.sortButton}>Region {sortKey === 'region' ? (sortDesc ? '▼' : '▲') : ''}</button></th>
                        <th className={tableStyles.th}><button onClick={sortByPool} className={tableStyles.sortButton}>Pools {sortKey === 'pool' ? (sortDesc ? '▼' : '▲') : ''}</button></th>
                        <th className={tableStyles.th}><button onClick={sortByAvgCpu} className={tableStyles.sortButton}>Avg CPU {sortKey === 'avgCpu' ? (sortDesc ? '▼' : '▲') : ''}</button></th>
                        <th className={tableStyles.th}><button onClick={sortByMaxSlice} className={tableStyles.sortButton}>Max Slice {sortKey === 'maxSlice' ? (sortDesc ? '▼' : '▲') : ''}</button></th>
                        <th className={tableStyles.th}><button onClick={sortByAvailability} className={tableStyles.sortButton}>Availability {sortKey === 'availability' ? (sortDesc ? '▼' : '▲') : ''}</button></th>
                        <th className={tableStyles.th}><button onClick={sortByNextRepave} className={tableStyles.sortButton}>Next Repave {sortKey === 'nextRepave' ? (sortDesc ? '▼' : '▲') : ''}</button></th>
                        <th className={tableStyles.th}>Select</th>
                    </tr>
                </thead>
                <tbody>
                    {pools.map((pool: Pool) => (
                        <tr key={pool.pool}>
                            <td className={tableStyles.td}>{pool.region}</td>
                            <td className={tableStyles.td}>{pool.pool}</td>
                            <td className={tableStyles.td}>
                                <div className={tableStyles.utilization}>
                                    <div className={`${tableStyles.utilizationBar} ${utilizationBarVariants[pool.avgCpu > 70 ? 'high' : pool.avgCpu > 50 ? 'medium' : 'low']}`} style={{ width: `${pool.avgCpu}%` }} />
                                    <span className={tableStyles.utilizationText}>{roundCpu(pool.avgCpu)}</span>
                                </div>
                            </td>
                            <td className={tableStyles.td}>{formatSlice(pool.instances[0].capacity.maxSlice)}</td>
                            <td className={tableStyles.td}>
                                <div className={tableStyles.utilization}>
                                    <div className={`${tableStyles.utilizationBar} ${utilizationBarVariants[getAvailabilityPercentage(pool.instances[0].capacity.available, pool.instances[0].capacity.total) > 70 ? 'high' : getAvailabilityPercentage(pool.instances[0].capacity.available, pool.instances[0].capacity.total) > 50 ? 'medium' : 'low']}`} style={{ width: `${getAvailabilityPercentage(pool.instances[0].capacity.available, pool.instances[0].capacity.total)}%` }} />
                                    <span className={tableStyles.utilizationText}>{getAvailabilityPercentage(pool.instances[0].capacity.available, pool.instances[0].capacity.total)}%</span>
                                </div>
                            </td>
                            <td className={tableStyles.td}>{pool.instances[0]?.nextRepave ? formatNextRepave(pool.instances[0].nextRepave) : 'N/A'}</td>
                            <td className={tableStyles.td}>
                                <input type="checkbox" checked={selectedPools.includes(pool)} onChange={() => togglePoolSelection(pool)} />
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
            <button onClick={() => setShowDialog(true)} className={tableStyles.showSelectedButton} disabled={selectedPools.length === 0}>
                Pools Chosen To Migrate
            </button>
            {showDialog && (
                <div className={dialogStyles.overlay}>
                    <div className={dialogStyles.dialog}>
                        <h2>Selected Pools</h2>
                        <ul className={tableStyles.selectedPools}>
                            {selectedPools.map((pool: Pool, index: number) => (
                                <li key={index}>{pool.pool}</li>
                            ))}
                        </ul>
                        <button onClick={handleContinue} className={dialogStyles.continueButton}>Yes</button>
                        <button onClick={() => setShowDialog(false)} className={dialogStyles.closeButton}>No</button>
                    </div>
                </div>
            )}
            {showMigrate && (
                <div className={dialogStyles.migrateSection}>
                    <h2>Selected Pools for Migration</h2>
                    <ul className={tableStyles.selectedPools}>
                        {selectedPools.map((pool: Pool, index: number) => (
                            <li key={index}>{pool.pool}</li>
                        ))}
                    </ul>
                    <button onClick={handleMigrate} className={dialogStyles.migrateButton}>Migrate App To Pool(s)</button>
                    <ServicesAndAppsPage apiLinks={migrationData.apiLinks} poolNames={migrationData.poolNames} />
                </div>
            )}
        </div>
    );
};

export default PoolTable;



import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { background, buttonStyle, successMessage } from './servicesAndApps.css';

interface MigrationComponentProps {
    apiLinks: { [key: string]: string };
    poolNames: string[];
}

interface Service {
    newPools: string;
    serviceName: string;
}

const ServicesAndAppsPage: React.FC<MigrationComponentProps> = ({ apiLinks, poolNames }) => {
    const [services, setServices] = useState<Service[]>([]);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);
    const [showBoolean, setShowBoolean] = useState<boolean>(true);
    const [successMessage, setSuccessMessage] = useState<string | null>(null);

    useEffect(() => {
        const fetchServices = async () => {
            try {
                const response = await axios.post("http://localhost:8080/createServices", {
                    newPools: poolNames,
                    serviceName: "",
                    user: "",
                    password: ""
                });
                const headers = {
                    'Content-Type': 'application/json'
                };
                setServices(response.data);
            } catch (error) {
                if (axios.isAxiosError(error)) {
                    setError(error.message);
                } else {
                    setError("Services Are having trouble creating ");
                }
            } finally {
                setLoading(false);
            }
        };

        fetchServices();
    }, [apiLinks, poolNames]);

    if (loading) return <div>In progress...</div>;
    if (error) return <div>{error}</div>;

    return (
        <div className={background}>
            <h1>Creating Services In New Pools</h1>
            <ul>
                {services.map((service: Service) => (
                    <li key={service.serviceName}>{service.serviceName}</li>
                ))}
            </ul>
            <h2>Selected Pool Names</h2>
            <ul>
                {poolNames.map((poolName: string, index: number) => (
                    <li key={index}>{poolName}</li>
                ))}
            </ul>
        </div>
    );
};

export default ServicesAndAppsPage;
