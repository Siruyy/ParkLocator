# System Scalability Architecture & Design

## High-Level Architecture
This diagram illustrates the fully scalable architecture of the ParkLocator system, featuring horizontal scaling, distributed caching, and real-time synchronization.

```mermaid
---
title: ParkLocator Scalable Architecture - Multi-Instance Deployment
---
graph TB
    subgraph Clients
        Mobile["Mobile App (Flutter)"]
        Web["Web Admin (Angular)"]
    end

    subgraph Load_Balancing["Load Balancing Layer"]
        LB["Load Balancer / Ingress"]
    end

    subgraph Application_Cluster["API Cluster (NestJS)"]
        Node1["API Instance 1"]
        Node2["API Instance 2"]
        Node3["API Instance N"]
    end

    subgraph Data_Layer["Data & Caching Layer"]
        RedisPrimary[("Redis Primary")]
        RedisReplica[("Redis Replica")]
        DB[("PostgreSQL + PostGIS")]
    end

    %% Client Connections
    Mobile -->|"REST / WSS"| LB
    Web -->|"REST / WSS"| LB

    %% Load Balancer Distribution
    LB -->|"Round Robin"| Node1
    LB -->|"Round Robin"| Node2
    LB -->|"Round Robin"| Node3

    %% Application Interactions - Database
    Node1 -->|"Read/Write"| DB
    Node2 -->|"Read/Write"| DB
    Node3 -->|"Read/Write"| DB

    %% Application Interactions - Redis (Cache + PubSub)
    Node1 <-->|"Cache / PubSub"| RedisPrimary
    Node2 <-->|"Cache / PubSub"| RedisPrimary
    Node3 <-->|"Cache / PubSub"| RedisPrimary
    
    RedisPrimary -.-|"Replication"| RedisReplica

    %% Internal Components style
    style Mobile fill:#e1f5fe,stroke:#01579b
    style Web fill:#e1f5fe,stroke:#01579b
    style DB fill:#e8f5e9,stroke:#2e7d32
    style RedisPrimary fill:#ffebee,stroke:#c62828
    style RedisReplica fill:#ffebee,stroke:#c62828
    style Node1 fill:#fff3e0,stroke:#ef6c00
    style Node2 fill:#fff3e0,stroke:#ef6c00
    style Node3 fill:#fff3e0,stroke:#ef6c00
```

## Detailed Component Interaction
This view details the internal modules of the NestJS API and how they interact during a critical flow like a **Reservation**.

```mermaid
---
title: Reservation Flow - Transaction & Real-time Sync
---
sequenceDiagram
    participant User as Mobile Client
    participant LB as Load Balancer
    participant API as API Instance
    participant Cache as Redis Cache
    participant DB as PostgreSQL
    participant Socket as Socket.io Room

    Note over User, Socket: Reservation Flow
    User->>LB: POST /reservations
    LB->>API: Route Request
    
    rect rgb(255, 240, 240)
        Note right of API: Transaction Start
        API->>DB: START TRANSACTION
        API->>DB: SELECT FOR UPDATE
        
        alt Spot Available
            API->>DB: INSERT Reservation
            API->>DB: UPDATE Spot Status
            API->>DB: COMMIT
            
            Note right of API: Invalidate Cache
            API->>Cache: DEL /venues/:id...
            
            Note right of API: Real-time Update
            API->>Cache: PUBLISH spot-update
            Cache->>API: Distribute event
            API->>Socket: EMIT spot-updated
            
            API-->>User: 201 Created
        else Spot Taken
            API->>DB: ROLLBACK
            API-->>User: 409 Conflict
        end
    end
```

## Caching Strategy & Data Flow
How data flows through the caching layer to ensure high performance (2.75ms P95 latency).

```mermaid
---
title: Caching Strategy - Redis Performance Optimization
---
flowchart TD
    Req["Incoming Request: GET /venues/nearby"] --> CheckCache{"Check Redis Cache"}
    
    CheckCache -->|"Hit (99%)"| ReturnCached["Return Cached JSON"]
    ReturnCached --> Client
    
    CheckCache -->|Miss| QueryDB["Query PostGIS Database"]
    QueryDB -->|Result| WriteCache["Write to Redis (TTL 30s)"]
    WriteCache --> ReturnFresh["Return Fresh Data"]
    ReturnFresh --> Client
    
    style CheckCache fill:#fff9c4,stroke:#fbc02d
    style ReturnCached fill:#c8e6c9,stroke:#2e7d32
    style QueryDB fill:#ffccbc,stroke:#d84315
```

## Database Schema (Scalability Focus)
Key entities involved in the high-concurrency booking system.

```mermaid
---
title: Database Schema - Core Booking Entities
---
erDiagram
    VENUE ||--|{ LEVEL : has
    VENUE ||--|{ RESERVATION : has
    LEVEL ||--|{ SPOT : contains
    SPOT ||--o{ RESERVATION : booked_in
    USER ||--|{ RESERVATION : makes
    USER ||--|{ VEHICLE : owns
    VEHICLE ||--o{ RESERVATION : used_for

    VENUE {
        uuid id PK
        string name
        geometry location
        jsonb configuration
    }

    SPOT {
        uuid id PK
        uuid level_id FK
        string status
        timestamp last_status_update
    }

    RESERVATION {
        uuid id PK
        uuid spot_id FK
        uuid user_id FK
        uuid vehicle_id FK
        timestamp start_at
        timestamp end_at
        string status
    }
```
