"use client";

import React from 'react';
import Link from 'next/link';
import { Law } from '@/types';
import styles from './LawCard.module.css';

interface LawCardProps {
  law: Law;
}

const LawCard: React.FC<LawCardProps> = ({ law }) => {
  return (
    <Link href={`/laws/${law.id}`} className={styles.lawCard}>
      <div className="law-card-content">
        <div className={styles.lawCardHeader}>
          <span className={styles.lawCategory}>{law.category}</span>
          <span className="law-date">{law.date}</span>
        </div>
        <h3 className={styles.lawTitle}>{law.title}</h3>
        <p className={styles.lawSummary}>{law.summary}</p>
        <div className={styles.lawCardFooter}>
          <span className={styles.readMore}>Lire le détail →</span>
        </div>
      </div>
    </Link>
  );
};

export default LawCard;
