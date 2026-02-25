"use client";

import Link from 'next/link';
import styles from './page.module.css';

export default function LoginPage() {
    return (
        <div className={styles.container}>
            <div className={styles.card}>
                <div className={styles.header}>
                    <h1 className={styles.title}>Connexion</h1>
                    <p className={styles.subtitle}>Accédez à votre espace</p>
                </div>

                <form className={styles.form}>
                    <div className={styles.inputGroup}>
                        <label htmlFor="email" className={styles.label}>
                            Adresse email
                        </label>
                        <input
                            type="email"
                            id="email"
                            name="email"
                            className={styles.input}
                            placeholder="exemple@email.com"
                            required
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label htmlFor="password" className={styles.label}>
                            Mot de passe
                        </label>
                        <input
                            type="password"
                            id="password"
                            name="password"
                            className={styles.input}
                            placeholder="••••••••"
                            required
                        />
                    </div>

                    <button type="submit" className={styles.submitButton}>
                        Se connecter
                    </button>
                </form>

                <div className={styles.footer}>
                    Pas encore de compte ?
                    <Link href="/register" className={styles.link}>
                        S'inscrire
                    </Link>
                </div>
            </div>
        </div>
    );
}
