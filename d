import { background, buttonStyles, successMessage } from "./servicesAndApps.css";
import React, { useEffect, useState } from "react";
import axios from "axios";

interface MigrationComponentProps {
    poolNames: string[];
    apiLink: string;
}

interface Service {
    newPools: string;
    serviceName: string;
}

const ServicesAndAppsPage: React.FC<MigrationComponentProps> = ({ poolNames, apiLink }) => {
    const [services, setServices] = useState<Service[]>([]);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const fetchServices = async () => {
            try {
                const response = await axios.post(apiLink, {
                    newPools: ["api.sys.dev.na-4z.gap.jpmchase.net"],
                    serviceName: [""],
                    user: "",
                    password: ""
                });
                setServices(response.data);
            } catch (error) {
                if (axios.isAxiosError(error)) {
                    setError(error.message);
                } else {
                    setError("Services are having trouble creating.");
                }
            } finally {
                setLoading(false);
            }
        };
        fetchServices();
    }, [apiLink]);

    if (loading) {
        return <div>In progress...</div>;
    }

    if (error) {
        return <div>FAILURE: {error}</div>;
    }

    return (
        <div className={background}>
            <h1>Creating Services in New Pools</h1>
            <ul>
                {services.map((service: Service) => (
                    <li key={service.serviceName}>{service.serviceName}</li>
                ))}
            </ul>
        </div>
    );
};

export default ServicesAndAppsPage;
const sortByAvailability = () => {
    const desc: boolean = sortKey === 'availability' ? !sortDesc : true;
    const sortedPools: Pool[] = [...pools].sort((a: Pool, b: Pool): number => {
        const aValue: number = (a.instances[0]?.capacity.available ?? 0) / (a.instances[0]?.capacity.total ?? 1) * 100;
        const bValue: number = (b.instances[0]?.capacity.available ?? 0) / (b.instances[0]?.capacity.total ?? 1) * 100;
        return desc ? bValue - aValue : aValue - bValue;
    });
    setPools(sortedPools);
    setSortKey('availability');
    setSortDesc(desc);
};
