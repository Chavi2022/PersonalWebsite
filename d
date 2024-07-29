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
            {/* ... (rest of the JSX remains the same until the ServicesAndAppsPage component) */}
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
