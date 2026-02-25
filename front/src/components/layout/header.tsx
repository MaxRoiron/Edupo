"use client";

import Link from "next/link";
import styles from './header.module.css';

export default function Header() {
  return (
    <header className={styles.header}>
      <div className={styles.container}>
        <Link href="/" className={styles.logo}>
          <span className={styles.logoBlue}>Édu</span>
          <span className={styles.logoRed}>po</span>
        </Link>
        <nav className={styles.nav}>
          <Link href="/" className={styles.navLink}>Accueil</Link>
          <Link href="/dashboard" className={styles.navLink}>Tableau de bord</Link>
          <Link href="/login" className={styles.authButton}>Connexion</Link>
        </nav>
      </div>
    </header>
  );
}